import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Manages encryption keys for SQLCipher databases.
///
/// Security:
/// - Keys are generated using cryptographically secure random number generator
/// - Keys are stored in platform-secure storage (Keychain on iOS, Keystore on Android)
/// - Keys are never stored in SharedPreferences or plain files
class DatabaseKeyManager {
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'aura_db_key_';

  // Key identifiers for different databases
  static const String cacheKey = 'cache';
  static const String historyKey = 'history';
  static const String auditKey = 'audit';

  DatabaseKeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
                storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Get or create a database encryption key.
  ///
  /// If no key exists for [keyId], generates a new 256-bit key.
  /// Returns the hex-encoded key suitable for SQLCipher.
  Future<String> getOrCreateKey(String keyId) async {
    final storageKey = '$_keyPrefix$keyId';

    // Try to retrieve existing key
    String? existingKey = await _secureStorage.read(key: storageKey);
    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    // Generate new key
    final newKey = _generateSecureKey();

    // Store key securely
    await _secureStorage.write(key: storageKey, value: newKey);

    return newKey;
  }

  /// Generate a cryptographically secure 256-bit key.
  String _generateSecureKey() {
    final random = Random.secure();
    final bytes = Uint8List(32); // 256 bits

    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    // Convert to hex string
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Delete a specific database key.
  ///
  /// Warning: This will make the associated database unreadable.
  Future<void> deleteKey(String keyId) async {
    final storageKey = '$_keyPrefix$keyId';
    await _secureStorage.delete(key: storageKey);
  }

  /// Delete all database keys.
  ///
  /// Warning: This will make all encrypted databases unreadable.
  Future<void> deleteAllKeys() async {
    await _secureStorage.delete(key: '$_keyPrefix$cacheKey');
    await _secureStorage.delete(key: '$_keyPrefix$historyKey');
    await _secureStorage.delete(key: '$_keyPrefix$auditKey');
  }

  /// Rotate a database key.
  ///
  /// Returns the new key. The caller is responsible for re-keying the database.
  Future<String> rotateKey(String keyId) async {
    final storageKey = '$_keyPrefix$keyId';
    final newKey = _generateSecureKey();
    await _secureStorage.write(key: storageKey, value: newKey);
    return newKey;
  }

  /// Check if a key exists for the given database.
  Future<bool> hasKey(String keyId) async {
    final storageKey = '$_keyPrefix$keyId';
    final key = await _secureStorage.read(key: storageKey);
    return key != null && key.isNotEmpty;
  }

  /// Derive a key from a password using PBKDF2.
  ///
  /// This is useful for user-provided passwords that need to be
  /// strengthened before use as a database key.
  String deriveKeyFromPassword(String password, String salt) {
    // Use PBKDF2 with HMAC-SHA256
    final hmac = Hmac(sha256, password.codeUnits);
    var key = Uint8List.fromList(salt.codeUnits);

    // 310,000 iterations as per OWASP recommendations
    for (var i = 0; i < 310000; i++) {
      final digest = hmac.convert(key);
      key = Uint8List.fromList(digest.bytes);
    }

    return key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
