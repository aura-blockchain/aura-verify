import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../domain/verification_record.dart';
import '../../../core/services/database_key_manager.dart';

/// Repository for verification history operations with encryption.
///
/// Security:
/// - Uses SQLCipher for AES-256 encryption at rest
/// - Encryption key stored in platform-secure storage
class HistoryRepository {
  Database? _database;
  final DatabaseKeyManager _keyManager;

  static const String _tableName = 'verification_history';
  static const String _databaseName = 'aura_verify_history.db';

  HistoryRepository({DatabaseKeyManager? keyManager})
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
    final encryptionKey = await _keyManager.getOrCreateKey(DatabaseKeyManager.historyKey);

    return await openDatabase(
      path,
      version: 1,
      password: encryptionKey, // SQLCipher encryption
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            holder_did TEXT NOT NULL,
            is_valid INTEGER NOT NULL,
            verified_at TEXT NOT NULL,
            verified_by TEXT NOT NULL,
            verified_by_username TEXT NOT NULL,
            result_type TEXT NOT NULL,
            error_message TEXT,
            network_latency_ms INTEGER NOT NULL,
            attributes TEXT
          )
        ''');

        // Create indexes
        await db.execute('''
          CREATE INDEX idx_history_timestamp ON $_tableName(verified_at DESC)
        ''');

        await db.execute('''
          CREATE INDEX idx_history_verified_by ON $_tableName(verified_by)
        ''');

        await db.execute('''
          CREATE INDEX idx_history_is_valid ON $_tableName(is_valid)
        ''');
      },
    );
  }

  /// Add verification record
  Future<VerificationRecord> add(VerificationRecord record) async {
    final db = await database;
    await db.insert(_tableName, record.toDatabase());
    return record;
  }

  /// Get all verification records with pagination
  Future<List<VerificationRecord>> getAll({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'verified_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => VerificationRecord.fromDatabase(map)).toList();
  }

  /// Get records by user
  Future<List<VerificationRecord>> getByUser(
    String userId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'verified_by = ?',
      whereArgs: [userId],
      orderBy: 'verified_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => VerificationRecord.fromDatabase(map)).toList();
  }

  /// Get records by date range
  Future<List<VerificationRecord>> getByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 1000,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'verified_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'verified_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => VerificationRecord.fromDatabase(map)).toList();
  }

  /// Get records by result type
  Future<List<VerificationRecord>> getByResultType(
    VerificationResultType resultType, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'result_type = ?',
      whereArgs: [resultType.code],
      orderBy: 'verified_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => VerificationRecord.fromDatabase(map)).toList();
  }

  /// Search records
  Future<List<VerificationRecord>> search(
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'holder_did LIKE ? OR verified_by_username LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'verified_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => VerificationRecord.fromDatabase(map)).toList();
  }

  /// Get statistics
  Future<HistoryStats> getStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE verified_at BETWEEN ? AND ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    }

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName $whereClause',
      whereArgs,
    );

    final successResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName $whereClause ${whereClause.isEmpty ? "WHERE" : "AND"} is_valid = 1',
      whereArgs,
    );

    final failedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName $whereClause ${whereClause.isEmpty ? "WHERE" : "AND"} is_valid = 0',
      whereArgs,
    );

    return HistoryStats(
      total: Sqflite.firstIntValue(totalResult) ?? 0,
      successful: Sqflite.firstIntValue(successResult) ?? 0,
      failed: Sqflite.firstIntValue(failedResult) ?? 0,
    );
  }

  /// Get today's statistics
  Future<HistoryStats> getTodayStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getStats(startDate: startOfDay, endDate: endOfDay);
  }

  /// Delete old records
  Future<int> deleteOlderThan(DateTime date) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'verified_at < ?',
      whereArgs: [date.toIso8601String()],
    );
  }

  /// Delete record by ID
  Future<void> deleteById(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all records
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Get count
  Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// History statistics
class HistoryStats {
  final int total;
  final int successful;
  final int failed;

  HistoryStats({
    required this.total,
    required this.successful,
    required this.failed,
  });

  double get successRate {
    if (total == 0) return 0.0;
    return (successful / total) * 100;
  }
}
