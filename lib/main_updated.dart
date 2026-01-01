import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/theme.dart';
import 'app/routes_updated.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/verification/bloc/verification_bloc.dart';
import 'core/services/aura_verification_service.dart';
import 'core/config/network_config.dart' as config;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait and landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Initialize repositories
  final authRepository = AuthRepository();
  await authRepository.initialize();

  // Initialize verification service
  final networkConfig = NetworkConfig.mainnet;
  final verificationService = AuraVerificationService(config: networkConfig);

  // Run the application
  runApp(
    AuraVerifyBusinessApp(
      authRepository: authRepository,
      verificationService: verificationService,
    ),
  );
}

/// Main application widget with BLoC providers
class AuraVerifyBusinessApp extends StatelessWidget {
  final AuthRepository authRepository;
  final VerificationService verificationService;

  const AuraVerifyBusinessApp({
    Key? key,
    required this.authRepository,
    required this.verificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider(
          create: (context) => AuthBloc(authRepository: authRepository)
            ..add(const AuthCheckRequested()),
        ),
        // Verification BLoC
        BlocProvider(
          create: (context) => VerificationBloc(
            verificationService: verificationService,
          ),
        ),
      ],
      child: const AppView(),
    );
  }
}

/// App view that rebuilds when auth state changes
class AppView extends StatelessWidget {
  const AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAuthenticated = state is AuthAuthenticated;

        return MaterialApp.router(
          title: 'Aura Verify Business',
          debugShowCheckedModeBanner: false,

          // Theme Configuration
          theme: AuraTheme.lightTheme,
          darkTheme: AuraTheme.darkTheme,
          themeMode: ThemeMode.system,

          // Router Configuration
          routerConfig: createAppRouter(isAuthenticated: isAuthenticated),

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
      },
    );
  }
}
