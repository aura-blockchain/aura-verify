import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';
import '../../domain/user_role.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  /// Security: Password intentionally excluded from props to prevent
  /// exposure in debug output, error messages, or logs.
  /// Equatable comparison uses only username.
  @override
  List<Object?> get props => [username];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionRefreshRequested extends AuthEvent {
  const AuthSessionRefreshRequested();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  Timer? _sessionTimer;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSessionRefreshRequested>(_onAuthSessionRefreshRequested);

    // Start session validation timer
    _startSessionTimer();
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final isSessionValid = await _authRepository.isSessionValid();
      if (!isSessionValid) {
        emit(const AuthUnauthenticated());
        return;
      }

      final user = await _authRepository.getCurrentUser();
      if (user != null && user.isActive) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.login(
        event.username,
        event.password,
      );

      emit(AuthAuthenticated(user: user));
    } on AuthException catch (e) {
      emit(AuthFailure(error: e.message));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(error: 'An unexpected error occurred'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isSessionValid = await _authRepository.isSessionValid();
      if (!isSessionValid) {
        emit(const AuthSessionExpired());
        await _authRepository.logout();
        emit(const AuthUnauthenticated());
        return;
      }

      await _authRepository.refreshSession();
    } catch (e) {
      // Ignore errors in session refresh
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const AuthSessionRefreshRequested());
    });
  }

  @override
  Future<void> close() {
    _sessionTimer?.cancel();
    return super.close();
  }
}
