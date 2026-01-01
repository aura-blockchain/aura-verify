/// Application-wide configuration constants
class AppConfig {
  // App Information
  static const String appName = 'Aura Verify Business';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Enterprise verification app for Aura blockchain credentials';

  // Age Verification Thresholds
  static const int legalDrinkingAge = 21;
  static const int legalAdultAge = 18;

  // Scanner Configuration
  static const int scannerTimeoutSeconds = 30;
  static const bool enableScannerVibration = true;
  static const bool enableScannerSound = true;

  // Verification Settings
  static const int verificationTimeoutSeconds = 10;
  static const int maxRetryAttempts = 3;
  static const bool requireOnlineVerification = true;

  // History Settings
  static const int maxHistoryEntries = 1000;
  static const int historyRetentionDays = 90;

  // UI Settings
  static const int successDisplayDuration = 3; // seconds
  static const int errorDisplayDuration = 5; // seconds
  static const double borderRadiusDefault = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 24.0;

  // Animation Durations
  static const int animationDurationShort = 200; // milliseconds
  static const int animationDurationMedium = 350; // milliseconds
  static const int animationDurationLong = 500; // milliseconds

  // Security
  static const bool enableSecureStorage = true;
  static const bool enableBiometricAuth = false; // Future feature
  static const int sessionTimeoutMinutes = 60;

  // Logging
  static const bool enableDetailedLogging = true;
  static const bool logToFile = false;

  // Privacy
  static const bool storeVerificationHistory = true;
  static const bool anonymizeHistoryData = false;

  // Development
  static const bool isDevelopment = true;
  static const bool enableDebugOverlay = false;

  AppConfig._(); // Private constructor to prevent instantiation
}
