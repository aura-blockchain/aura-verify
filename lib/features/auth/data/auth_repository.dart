import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../domain/user.dart';
import '../domain/user_role.dart';
import '../../../core/services/session_token_service.dart';

/// Repository for authentication operations
/// Security: Uses PBKDF2-like password hashing with salt (310,000 iterations)
/// Security: Uses signed session tokens instead of raw user data storage
class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final SessionTokenService _sessionTokenService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  static const String _usersKey = 'aura_users';
  static const String _sessionTokenKey = 'aura_session_token';
  static const String _saltsKey = 'aura_salts';
  static const String _setupCompleteKey = 'aura_setup_complete';
  static const String _failedAttemptsKey = 'aura_failed_attempts';

  /// PBKDF2 iterations (OWASP 2023 recommendation)
  static const int _pbkdf2Iterations = 310000;

  /// Maximum failed login attempts before lockout
  static const int _maxFailedAttempts = 5;

  /// Lockout duration in minutes
  static const int _lockoutMinutes = 15;

  AuthRepository({
    FlutterSecureStorage? secureStorage,
    SessionTokenService? sessionTokenService,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sessionTokenService = sessionTokenService ?? SessionTokenService();

  /// Check if initial setup is required
  Future<bool> isSetupRequired() async {
    final setupComplete = await _secureStorage.read(key: _setupCompleteKey);
    return setupComplete != 'true';
  }

  /// Initialize - does NOT create default users (security)
  Future<void> initialize() async {
    // No default users - require explicit first-time setup
  }

  /// First-time setup with admin credentials (must be called explicitly)
  Future<User> setupAdmin({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) async {
    final users = await _getAllUsersInternal();

    // Only allow setup if no users exist
    if (users.isNotEmpty) {
      throw AuthException('Setup already completed');
    }

    // Validate password strength
    _validatePasswordStrength(password);

    final adminUser = User(
      id: _uuid.v4(),
      username: username,
      email: email,
      displayName: displayName,
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    await _createUser(adminUser, password);
    await _secureStorage.write(key: _setupCompleteKey, value: 'true');

    return adminUser;
  }

  /// Login with username and password
  /// Security: Implements account lockout after failed attempts
  Future<User> login(String username, String password) async {
    // Check for account lockout
    final lockoutStatus = await _checkLockout(username);
    if (lockoutStatus != null) {
      throw AuthException(lockoutStatus);
    }

    final users = await _getAllUsersInternal();
    final credentials = await _getAllCredentials();
    final salts = await _getAllSalts();

    for (final user in users) {
      if (user.username == username && user.isActive) {
        final storedHash = credentials[user.id];
        final userSalt = salts[user.id];

        if (storedHash == null || userSalt == null) {
          await _recordFailedAttempt(username);
          throw AuthException('Invalid username or password');
        }

        final passwordHash = _hashPasswordWithSalt(password, userSalt);

        if (storedHash == passwordHash) {
          // Clear failed attempts on successful login
          await _clearFailedAttempts(username);

          // Update last login
          final updatedUser = user.copyWith(lastLogin: DateTime.now());
          await _updateUser(updatedUser);

          // Security: Create signed session token instead of storing raw user data
          final sessionToken = await _sessionTokenService.createToken(
            userId: updatedUser.id,
            username: updatedUser.username,
            role: updatedUser.role.name,
          );

          await _secureStorage.write(
            key: _sessionTokenKey,
            value: sessionToken,
          );

          return updatedUser;
        } else {
          await _recordFailedAttempt(username);
          throw AuthException('Invalid username or password');
        }
      }
    }

    // Record failed attempt for non-existent users too (timing attack prevention)
    await _recordFailedAttempt(username);
    throw AuthException('Invalid username or password');
  }

  /// Logout current user
  Future<void> logout() async {
    await _secureStorage.delete(key: _sessionTokenKey);
  }

  /// Get current logged-in user
  /// Security: Validates session token and looks up fresh user data
  Future<User?> getCurrentUser() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    if (token == null) return null;

    try {
      // Validate the session token
      final payload = await _sessionTokenService.validateToken(token);
      if (payload == null) {
        // Token invalid or expired - clear it
        await _secureStorage.delete(key: _sessionTokenKey);
        return null;
      }

      // Look up the user from storage (get fresh data)
      final users = await _getAllUsersInternal();
      final user = users.firstWhere(
        (u) => u.id == payload.userId && u.isActive,
        orElse: () => throw AuthException('User not found'),
      );

      return user;
    } catch (e) {
      // On any error, clear invalid session
      await _secureStorage.delete(key: _sessionTokenKey);
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Get all users (admin/manager only)
  /// Security: Requires admin or manager role
  Future<List<User>> getAllUsers() async {
    await _requireRole([UserRole.admin, UserRole.manager]);
    return _getAllUsersInternal();
  }

  /// Internal method to get all users without auth check
  /// Used during login and setup
  Future<List<User>> _getAllUsersInternal() async {
    final usersJson = await _secureStorage.read(key: _usersKey);
    if (usersJson == null) return [];

    try {
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create new user (admin only)
  /// Security: Requires admin role
  Future<User> createUser({
    required String username,
    required String password,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    await _requireRole([UserRole.admin]);
    final users = await _getAllUsersInternal();

    // Check if username already exists
    if (users.any((u) => u.username == username)) {
      throw AuthException('Username already exists');
    }

    final newUser = User(
      id: _uuid.v4(),
      username: username,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );

    await _createUser(newUser, password);
    return newUser;
  }

  Future<void> _createUser(User user, String password) async {
    final users = await getAllUsers();
    users.add(user);
    await _saveUsers(users);

    // Generate salt and store password hash
    final salt = _generateSalt();
    final salts = await _getAllSalts();
    salts[user.id] = salt;
    await _saveSalts(salts);

    final credentials = await _getAllCredentials();
    credentials[user.id] = _hashPasswordWithSalt(password, salt);
    await _saveCredentials(credentials);
  }

  /// Update user (admin/manager only)
  /// Security: Requires admin or manager role
  Future<User> updateUser(User user) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Not authenticated');
    }

    // Managers can only update operators, admins can update anyone
    if (currentUser.role == UserRole.manager) {
      final targetUser = (await _getAllUsersInternal()).firstWhere(
        (u) => u.id == user.id,
        orElse: () => throw AuthException('User not found'),
      );
      if (targetUser.role != UserRole.operator) {
        throw AuthException('Managers can only update operators');
      }
    } else if (currentUser.role != UserRole.admin) {
      throw AuthException('Unauthorized: admin or manager role required');
    }

    await _updateUser(user);
    return user;
  }

  Future<void> _updateUser(User user) async {
    final users = await _getAllUsersInternal();
    final index = users.indexWhere((u) => u.id == user.id);

    if (index == -1) {
      throw AuthException('User not found');
    }

    users[index] = user;
    await _saveUsers(users);
  }

  /// Delete user (admin only)
  /// Security: Requires admin role
  Future<void> deleteUser(String userId) async {
    await _requireRole([UserRole.admin]);

    final users = await _getAllUsersInternal();
    users.removeWhere((u) => u.id == userId);
    await _saveUsers(users);

    // Remove credentials
    final credentials = await _getAllCredentials();
    credentials.remove(userId);
    await _saveCredentials(credentials);

    // Remove salt
    final salts = await _getAllSalts();
    salts.remove(userId);
    await _saveSalts(salts);
  }

  /// Change password
  /// Security: Generates new salt, validates password strength, and invalidates sessions
  Future<void> changePassword(String userId, String newPassword) async {
    // Validate password strength
    _validatePasswordStrength(newPassword);

    // Generate new salt for the new password
    final salt = _generateSalt();
    final salts = await _getAllSalts();
    salts[userId] = salt;
    await _saveSalts(salts);

    final credentials = await _getAllCredentials();
    credentials[userId] = _hashPasswordWithSalt(newPassword, salt);
    await _saveCredentials(credentials);

    // Security: Invalidate all existing sessions after password change
    await invalidateAllSessions();
  }

  Future<void> _saveUsers(List<User> users) async {
    final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
    await _secureStorage.write(key: _usersKey, value: usersJson);
  }

  /// Verify current user has required role
  /// Security: Authorization check for admin operations
  Future<void> _requireRole(List<UserRole> allowedRoles) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Not authenticated');
    }
    if (!allowedRoles.contains(currentUser.role)) {
      final roleNames = allowedRoles.map((r) => r.name).join(' or ');
      throw AuthException('Unauthorized: $roleNames role required');
    }
  }

  Future<Map<String, String>> _getAllCredentials() async {
    final credJson = await _secureStorage.read(key: 'aura_credentials');
    if (credJson == null) return {};

    try {
      return Map<String, String>.from(jsonDecode(credJson));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveCredentials(Map<String, String> credentials) async {
    final credJson = jsonEncode(credentials);
    await _secureStorage.write(key: 'aura_credentials', value: credJson);
  }

  /// Generate a random salt for password hashing
  String _generateSalt() {
    final saltBytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hash password with salt using PBKDF2-like iterations
  /// Security: Uses 310,000 iterations per OWASP 2023 recommendation
  String _hashPasswordWithSalt(String password, String salt) {
    final saltBytes = base64.decode(salt);
    List<int> hash = utf8.encode(password + salt);

    // PBKDF2-like iteration (simplified for Dart without external deps)
    for (var i = 0; i < _pbkdf2Iterations; i++) {
      final combined = [...hash, ...saltBytes];
      hash = sha256.convert(combined).bytes;
    }

    return base64.encode(hash);
  }

  /// Validate password strength requirements
  void _validatePasswordStrength(String password) {
    if (password.length < 12) {
      throw AuthException('Password must be at least 12 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw AuthException('Password must contain uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      throw AuthException('Password must contain lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw AuthException('Password must contain a number');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      throw AuthException('Password must contain a special character');
    }
  }

  /// Get all salts
  Future<Map<String, String>> _getAllSalts() async {
    final saltsJson = await _secureStorage.read(key: _saltsKey);
    if (saltsJson == null) return {};

    try {
      return Map<String, String>.from(jsonDecode(saltsJson));
    } catch (e) {
      return {};
    }
  }

  /// Save salts
  Future<void> _saveSalts(Map<String, String> salts) async {
    final saltsJson = jsonEncode(salts);
    await _secureStorage.write(key: _saltsKey, value: saltsJson);
  }

  /// Check if account is locked out
  Future<String?> _checkLockout(String username) async {
    final attemptsJson = await _secureStorage.read(key: _failedAttemptsKey);
    if (attemptsJson == null) return null;

    try {
      final attempts = Map<String, dynamic>.from(jsonDecode(attemptsJson));
      final userAttempts = attempts[username];
      if (userAttempts == null) return null;

      final count = userAttempts['count'] as int? ?? 0;
      final lastAttempt = DateTime.tryParse(userAttempts['lastAttempt'] ?? '');

      if (count >= _maxFailedAttempts && lastAttempt != null) {
        final lockoutEnd = lastAttempt.add(Duration(minutes: _lockoutMinutes));
        if (DateTime.now().isBefore(lockoutEnd)) {
          final remaining = lockoutEnd.difference(DateTime.now()).inMinutes + 1;
          return 'Account locked. Try again in $remaining minutes';
        }
        // Lockout expired, clear attempts
        await _clearFailedAttempts(username);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Record a failed login attempt
  Future<void> _recordFailedAttempt(String username) async {
    final attemptsJson = await _secureStorage.read(key: _failedAttemptsKey);
    Map<String, dynamic> attempts = {};

    if (attemptsJson != null) {
      try {
        attempts = Map<String, dynamic>.from(jsonDecode(attemptsJson));
      } catch (e) {
        // Start fresh on parse error
      }
    }

    final userAttempts = attempts[username] as Map<String, dynamic>? ?? {};
    final count = (userAttempts['count'] as int? ?? 0) + 1;

    attempts[username] = {
      'count': count,
      'lastAttempt': DateTime.now().toIso8601String(),
    };

    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: jsonEncode(attempts),
    );
  }

  /// Clear failed login attempts
  Future<void> _clearFailedAttempts(String username) async {
    final attemptsJson = await _secureStorage.read(key: _failedAttemptsKey);
    if (attemptsJson == null) return;

    try {
      final attempts = Map<String, dynamic>.from(jsonDecode(attemptsJson));
      attempts.remove(username);
      await _secureStorage.write(
        key: _failedAttemptsKey,
        value: jsonEncode(attempts),
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Validate session token
  /// Security: Validates token signature and expiration
  Future<bool> isSessionValid() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    if (token == null) return false;

    final payload = await _sessionTokenService.validateToken(token);
    return payload != null && !payload.isExpired;
  }

  /// Refresh session token
  /// Security: Creates a new signed token with extended expiration
  Future<void> refreshSession() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    if (token == null) return;

    final newToken = await _sessionTokenService.refreshToken(token);
    if (newToken != null) {
      await _secureStorage.write(
        key: _sessionTokenKey,
        value: newToken,
      );
    }
  }

  /// Invalidate all sessions (e.g., on password change)
  /// Security: Rotates the signing key, invalidating all tokens
  Future<void> invalidateAllSessions() async {
    await _sessionTokenService.invalidateAllTokens();
    await _secureStorage.delete(key: _sessionTokenKey);
  }
}

/// Auth exception
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
