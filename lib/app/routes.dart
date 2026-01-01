import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/scanner/presentation/scanner_screen.dart';
import '../features/verification/presentation/result_screen.dart';

/// Route names and paths
class AppRoutes {
  static const String home = '/';
  static const String scanner = '/';
  static const String result = '/result';
  static const String history = '/history';
  static const String settings = '/settings';
}

/// GoRouter configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    // Home/Scanner Route
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
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

    // History Route (placeholder for future implementation)
    GoRoute(
      path: AppRoutes.history,
      name: 'history',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const HistoryPlaceholderScreen(),
      ),
    ),

    // Settings Route (placeholder for future implementation)
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const SettingsPlaceholderScreen(),
      ),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: ErrorScreen(error: state.error.toString()),
  ),
);

/// Placeholder for History Screen (to be implemented)
class HistoryPlaceholderScreen extends StatelessWidget {
  const HistoryPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification History'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'History Feature',
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

/// Placeholder for Settings Screen (to be implemented)
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Settings Feature',
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
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
