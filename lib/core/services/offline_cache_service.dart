import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'database_key_manager.dart';

/// Service for offline verification cache with encryption.
///
/// Security:
/// - Uses SQLCipher for AES-256 encryption at rest
/// - Encryption key stored in platform-secure storage
/// - All cached verification data is encrypted
class OfflineCacheService {
  Database? _database;
  final DatabaseKeyManager _keyManager;

  static const String _tableName = 'offline_cache';
  static const String _databaseName = 'aura_verify_cache.db';

  OfflineCacheService({DatabaseKeyManager? keyManager})
      : _keyManager = keyManager ?? DatabaseKeyManager();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    // Get encryption key from secure storage
    final encryptionKey = await _keyManager.getOrCreateKey(DatabaseKeyManager.cacheKey);

    return await openDatabase(
      path,
      version: 1,
      password: encryptionKey, // SQLCipher encryption
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            holder_did TEXT PRIMARY KEY,
            verification_data TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            is_valid INTEGER NOT NULL
          )
        ''');

        // Create index on expiration
        await db.execute('''
          CREATE INDEX idx_cache_expires ON $_tableName(expires_at)
        ''');
      },
    );
  }

  /// Cache verification result
  Future<void> cacheVerification({
    required String holderDID,
    required Map<String, dynamic> verificationData,
    required bool isValid,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(cacheDuration);

    await db.insert(
      _tableName,
      {
        'holder_did': holderDID,
        'verification_data': jsonEncode(verificationData),
        'cached_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_valid': isValid ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached verification
  Future<CachedVerification?> getCached(String holderDID) async {
    final db = await database;
    final results = await db.query(
      _tableName,
      where: 'holder_did = ?',
      whereArgs: [holderDID],
    );

    if (results.isEmpty) return null;

    final cached = CachedVerification.fromMap(results.first);

    // Check if expired
    if (cached.expiresAt.isBefore(DateTime.now())) {
      await deleteCached(holderDID);
      return null;
    }

    return cached;
  }

  /// Check if verification is cached and valid
  Future<bool> isCached(String holderDID) async {
    final cached = await getCached(holderDID);
    return cached != null;
  }

  /// Delete cached verification
  Future<void> deleteCached(String holderDID) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'holder_did = ?',
      whereArgs: [holderDID],
    );
  }

  /// Delete expired cache entries
  Future<int> deleteExpired() async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  /// Clear all cache
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Clear all cached credentials (alias for clearAll)
  Future<void> clearAllCachedCredentials() async {
    await clearAll();
  }

  /// Sync with network (delete expired, refresh if possible)
  Future<void> syncWithNetwork() async {
    // Delete expired entries
    await deleteExpired();
    // Note: Full sync with remote would require network service
    // This is a local-only implementation for now
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );

    final validResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE expires_at > ?',
      [DateTime.now().toIso8601String()],
    );

    return CacheStats(
      total: Sqflite.firstIntValue(totalResult) ?? 0,
      valid: Sqflite.firstIntValue(validResult) ?? 0,
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Cached verification model
class CachedVerification {
  final String holderDID;
  final Map<String, dynamic> verificationData;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final bool isValid;

  CachedVerification({
    required this.holderDID,
    required this.verificationData,
    required this.cachedAt,
    required this.expiresAt,
    required this.isValid,
  });

  factory CachedVerification.fromMap(Map<String, dynamic> map) {
    return CachedVerification(
      holderDID: map['holder_did'] ?? '',
      verificationData: jsonDecode(map['verification_data'] ?? '{}'),
      cachedAt: DateTime.tryParse(map['cached_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] ?? '') ?? DateTime.now(),
      isValid: (map['is_valid'] ?? 0) == 1,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}

/// Cache statistics
class CacheStats {
  final int total;
  final int valid;

  CacheStats({
    required this.total,
    required this.valid,
  });

  int get expired => total - valid;
}
