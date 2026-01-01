/// User roles for role-based access control
enum UserRole {
  admin('admin', 'Administrator', 'Full system access'),
  manager('manager', 'Manager', 'Manage users and view reports'),
  operator('operator', 'Operator', 'Verify credentials only');

  final String code;
  final String displayName;
  final String description;

  const UserRole(this.code, this.displayName, this.description);

  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.operator;
    }
  }

  bool hasPermission(Permission permission) {
    switch (this) {
      case UserRole.admin:
        return true; // Admin has all permissions
      case UserRole.manager:
        return permission != Permission.manageUsers &&
            permission != Permission.systemSettings;
      case UserRole.operator:
        return permission == Permission.scanCredentials ||
            permission == Permission.viewHistory;
    }
  }
}

/// Permissions for different actions
enum Permission {
  scanCredentials,
  viewHistory,
  exportData,
  manageUsers,
  systemSettings,
  viewAuditLog,
  batchVerification,
}
