import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../domain/audit_entry.dart';
import '../../../core/services/database_key_manager.dart';

/// Repository for audit log operations with encryption.
///
/// Security:
/// - Uses SQLCipher for AES-256 encryption at rest
/// - Encryption key stored in platform-secure storage
/// - Audit logs contain sensitive operation data
class AuditRepository {
  Database? _database;
  final Uuid _uuid = const Uuid();
  final DatabaseKeyManager _keyManager;

  static const String _tableName = 'audit_log';
  static const String _databaseName = 'aura_verify_audit.db';

  AuditRepository({DatabaseKeyManager? keyManager})
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
    final encryptionKey = await _keyManager.getOrCreateKey(DatabaseKeyManager.auditKey);

    return await openDatabase(
      path,
      version: 1,
      password: encryptionKey, // SQLCipher encryption
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            username TEXT NOT NULL,
            action TEXT NOT NULL,
            description TEXT NOT NULL,
            metadata TEXT,
            timestamp TEXT NOT NULL,
            ip_address TEXT,
            device_info TEXT
          )
        ''');

        // Create index on timestamp for faster queries
        await db.execute('''
          CREATE INDEX idx_audit_timestamp ON $_tableName(timestamp DESC)
        ''');

        // Create index on user_id for user-specific queries
        await db.execute('''
          CREATE INDEX idx_audit_user ON $_tableName(user_id)
        ''');

        // Create index on action for action-specific queries
        await db.execute('''
          CREATE INDEX idx_audit_action ON $_tableName(action)
        ''');
      },
    );
  }

  /// Log an audit entry
  Future<AuditEntry> log({
    required String userId,
    required String username,
    required AuditAction action,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final entry = AuditEntry(
      id: _uuid.v4(),
      userId: userId,
      username: username,
      action: action,
      description: description,
      metadata: metadata,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );

    final db = await database;
    await db.insert(_tableName, entry.toDatabase());

    return entry;
  }

  /// Get all audit entries with pagination
  Future<List<AuditEntry>> getAll({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AuditEntry.fromDatabase(map)).toList();
  }

  /// Get audit entries for a specific user
  Future<List<AuditEntry>> getByUser(
    String userId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AuditEntry.fromDatabase(map)).toList();
  }

  /// Get audit entries for a specific action
  Future<List<AuditEntry>> getByAction(
    AuditAction action, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'action = ?',
      whereArgs: [action.code],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AuditEntry.fromDatabase(map)).toList();
  }

  /// Get audit entries within a date range
  Future<List<AuditEntry>> getByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 1000,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AuditEntry.fromDatabase(map)).toList();
  }

  /// Search audit entries
  Future<List<AuditEntry>> search(
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'description LIKE ? OR username LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AuditEntry.fromDatabase(map)).toList();
  }

  /// Get count of all audit entries
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get count by action
  Future<int> getCountByAction(AuditAction action) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE action = ?',
      [action.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete old entries (cleanup)
  Future<int> deleteOlderThan(DateTime date) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [date.toIso8601String()],
    );
  }

  /// Clear all audit entries
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
