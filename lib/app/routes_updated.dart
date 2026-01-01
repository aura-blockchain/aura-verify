import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/verification/presentation/result_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/batch/presentation/batch_verification_screen.dart';

/// Route names and paths
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/';
  static const String scanner = '/scanner';
  static const String result = '/result';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String batch = '/batch';
  static const String audit = '/audit';
  static const String users = '/users';
}

/// GoRouter configuration with authentication
GoRouter createAppRouter({
  required bool isAuthenticated,
}) {
  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // If not authenticated and not going to login, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If authenticated and on login screen, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        return AppRoutes.dashboard;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Login Route
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      // Dashboard Route
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),

      // Scanner Route
      GoRoute(
        path: AppRoutes.scanner,
        name: 'scanner',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ScannerScreen(),
        ),
      ),

      // Verification Result Route
      GoRoute(
        path: AppRoutes.result,
        name: 'result',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: ResultScreen(
              verificationData: extra ?? {},
            ),
          );
        },
      ),

      // History Route
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HistoryScreen(),
        ),
      ),

      // Settings Route
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),

      // Batch Verification Route
      GoRoute(
        path: AppRoutes.batch,
        name: 'batch',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BatchVerificationScreen(),
        ),
      ),

      // Audit Log Route (placeholder)
      GoRoute(
        path: AppRoutes.audit,
        name: 'audit',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuditLogPlaceholderScreen(),
        ),
      ),

      // User Management Route (placeholder)
      GoRoute(
        path: AppRoutes.users,
        name: 'users',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const UserManagementPlaceholderScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(error: state.error.toString()),
    ),
  );
}

/// Placeholder for Audit Log Screen
class AuditLogPlaceholderScreen extends StatelessWidget {
  const AuditLogPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Audit Log',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for User Management Screen
class UserManagementPlaceholderScreen extends StatelessWidget {
  const UserManagementPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}

/// Error Screen
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
