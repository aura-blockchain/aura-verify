import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes.dart';
import 'theme.dart';

/// Main application widget
class AuraVerifyBusinessApp extends StatelessWidget {
  const AuraVerifyBusinessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp.router(
      title: 'Aura Verify Business',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AuraTheme.lightTheme,
      darkTheme: AuraTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Router Configuration
      routerConfig: appRouter,

      // Builder for additional wrappers
      builder: (context, child) {
        // Ensure text scaling doesn't break the UI
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
