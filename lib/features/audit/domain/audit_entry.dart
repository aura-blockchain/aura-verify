import 'package:equatable/equatable.dart';

/// Audit entry model for tracking all system actions
class AuditEntry extends Equatable {
  final String id;
  final String userId;
  final String username;
  final AuditAction action;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceInfo;

  const AuditEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.action,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        action,
        description,
        metadata,
        timestamp,
        ipAddress,
        deviceInfo,
      ];

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      action: AuditAction.fromString(json['action']),
      description: json['description'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      ipAddress: json['ip_address'],
      deviceInfo: json['device_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action': action.code,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'device_info': deviceInfo,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action': action.code,
      'description': description,
      'metadata': metadata.toString(),
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'device_info': deviceInfo,
    };
  }

  factory AuditEntry.fromDatabase(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? '',
      action: AuditAction.fromString(map['action']),
      description: map['description'] ?? '',
      metadata: {},
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      ipAddress: map['ip_address'],
      deviceInfo: map['device_info'],
    );
  }
}

/// Audit action types
enum AuditAction {
  login('login', 'User Login'),
  logout('logout', 'User Logout'),
  verifyCredential('verify_credential', 'Verify Credential'),
  batchVerify('batch_verify', 'Batch Verification'),
  exportData('export_data', 'Export Data'),
  createUser('create_user', 'Create User'),
  updateUser('update_user', 'Update User'),
  deleteUser('delete_user', 'Delete User'),
  changePassword('change_password', 'Change Password'),
  updateSettings('update_settings', 'Update Settings'),
  viewAuditLog('view_audit_log', 'View Audit Log'),
  viewHistory('view_history', 'View History'),
  deleteHistory('delete_history', 'Delete History'),
  systemError('system_error', 'System Error');

  final String code;
  final String displayName;

  const AuditAction(this.code, this.displayName);

  static AuditAction fromString(String? value) {
    return AuditAction.values.firstWhere(
      (e) => e.code == value,
      orElse: () => AuditAction.systemError,
    );
  }
}
