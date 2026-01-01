import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for creating and validating signed session tokens.
///
/// Security:
/// - Uses HMAC-SHA256 for token signing
/// - Secret key stored in platform-secure storage
/// - Tokens include expiration and are tamper-resistant
/// - Replaces storing raw user JSON in session storage
class SessionTokenService {
  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();

  static const String _secretKeyKey = 'aura_session_secret';
  static const int _tokenValidityMinutes = 60;

  SessionTokenService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Create a signed session token for a user
  ///
  /// Token format: base64(payload).base64(signature)
  /// Payload: { userId, username, role, issuedAt, expiresAt }
  Future<String> createToken({
    required String userId,
    required String username,
    required String role,
  }) async {
    final secret = await _getOrCreateSecret();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: _tokenValidityMinutes));

    final payload = {
      'sub': userId, // subject (user ID)
      'usr': username,
      'role': role,
      'iat': now.millisecondsSinceEpoch, // issued at
      'exp': expiresAt.millisecondsSinceEpoch, // expires at
      'jti': _generateTokenId(), // unique token ID
    };

    final payloadJson = jsonEncode(payload);
    final payloadBase64 = base64Url.encode(utf8.encode(payloadJson));

    // Create HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(secret));
    final signature = hmac.convert(utf8.encode(payloadBase64));
    final signatureBase64 = base64Url.encode(signature.bytes);

    return '$payloadBase64.$signatureBase64';
  }

  /// Validate and decode a session token
  ///
  /// Returns the payload if valid, null if invalid or expired
  Future<SessionPayload?> validateToken(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;

      final payloadBase64 = parts[0];
      final signatureBase64 = parts[1];

      // Verify signature
      final secret = await _getOrCreateSecret();
      final hmac = Hmac(sha256, utf8.encode(secret));
      final expectedSignature = hmac.convert(utf8.encode(payloadBase64));
      final expectedSignatureBase64 = base64Url.encode(expectedSignature.bytes);

      // Constant-time comparison to prevent timing attacks
      if (!_constantTimeEquals(signatureBase64, expectedSignatureBase64)) {
        return null;
      }

      // Decode payload
      final payloadJson = utf8.decode(base64Url.decode(payloadBase64));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // Check expiration
      final expiresAt = payload['exp'] as int?;
      if (expiresAt == null) return null;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(expiresAt);
      if (DateTime.now().isAfter(expirationTime)) {
        return null; // Token expired
      }

      return SessionPayload(
        userId: payload['sub'] as String? ?? '',
        username: payload['usr'] as String? ?? '',
        role: payload['role'] as String? ?? '',
        issuedAt: DateTime.fromMillisecondsSinceEpoch(payload['iat'] as int? ?? 0),
        expiresAt: expirationTime,
        tokenId: payload['jti'] as String? ?? '',
      );
    } catch (e) {
      return null; // Any error means invalid token
    }
  }

  /// Refresh a token (creates new token with same user info, new expiration)
  Future<String?> refreshToken(String token) async {
    final payload = await validateToken(token);
    if (payload == null) return null;

    return createToken(
      userId: payload.userId,
      username: payload.username,
      role: payload.role,
    );
  }

  /// Invalidate all tokens by rotating the secret
  /// Security: Use this on password change or security breach
  Future<void> invalidateAllTokens() async {
    await _rotateSecret();
  }

  /// Get or create the HMAC secret key
  Future<String> _getOrCreateSecret() async {
    var secret = await _secureStorage.read(key: _secretKeyKey);
    if (secret == null || secret.isEmpty) {
      secret = _generateSecret();
      await _secureStorage.write(key: _secretKeyKey, value: secret);
    }
    return secret;
  }

  /// Rotate the secret key (invalidates all existing tokens)
  Future<void> _rotateSecret() async {
    final newSecret = _generateSecret();
    await _secureStorage.write(key: _secretKeyKey, value: newSecret);
  }

  /// Generate a cryptographically secure secret key
  String _generateSecret() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Generate a unique token ID
  String _generateTokenId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      // Still do comparison to maintain constant time
      final maxLen = a.length > b.length ? a.length : b.length;
      a = a.padRight(maxLen, '\x00');
      b = b.padRight(maxLen, '\x00');
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Decoded session payload
class SessionPayload {
  final String userId;
  final String username;
  final String role;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String tokenId;

  SessionPayload({
    required this.userId,
    required this.username,
    required this.role,
    required this.issuedAt,
    required this.expiresAt,
    required this.tokenId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}
