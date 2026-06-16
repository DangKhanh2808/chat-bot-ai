import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/auth_repository.dart';
import '../utils/validators.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final Logger logger;

  AuthBloc({
    required this.authRepository,
    Logger? logger,
  })  : logger = logger ?? Logger(),
        super(const AuthInitial()) {
    // Register event handlers
    on<AuthInitialized>(_onAuthInitialized);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthGoogleSigninRequested>(_onAuthGoogleSigninRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
  }

  /// Handle AuthInitialized event - Check if user is already logged in
  Future<void> _onAuthInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final isAuthenticated = await authRepository.isUserAuthenticated();
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
          return;
        }
      }

      emit(const AuthUnauthenticated());
    } catch (e) {
      logger.e('Error initializing auth: $e');
      emit(
        AuthError(
          message: 'Failed to check authentication status',
          errorCode: 'init_error',
        ),
      );
    }
  }

  /// Handle AuthLoginRequested event
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Validate inputs
      final validations = validateLoginInputs(
        email: event.email,
        password: event.password,
      );

      if (!isValidationSuccessful(validations)) {
        final firstError = validations.values.firstWhere(
          (error) => error != null,
          orElse: () => null,
        );
        emit(AuthError(message: firstError ?? 'Validation failed'));
        return;
      }

      emit(const AuthLoading());

      final user = await authRepository.loginWithEmail(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      logger.e('Error during login: $e');
      final errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  /// Handle AuthSignupRequested event
  Future<void> _onAuthSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Validate inputs
      final validations = validateSignupInputs(
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );

      if (!isValidationSuccessful(validations)) {
        final firstError = validations.values.firstWhere(
          (error) => error != null,
          orElse: () => null,
        );
        emit(AuthError(message: firstError ?? 'Validation failed'));
        return;
      }

      emit(const AuthLoading());

      final user = await authRepository.signupWithEmail(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      logger.e('Error during signup: $e');
      final errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  /// Handle AuthGoogleSigninRequested event
  Future<void> _onAuthGoogleSigninRequested(
    AuthGoogleSigninRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await authRepository.loginWithGoogle();

      emit(AuthAuthenticated(user: user));
    } catch (e) {
      logger.e('Error during Google signin: $e');
      final errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  /// Handle AuthLogoutRequested event
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      await authRepository.logout();

      emit(const AuthUnauthenticated());
    } catch (e) {
      logger.e('Error during logout: $e');
      final errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  /// Handle AuthPasswordResetRequested event
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Validate email
      final emailError = validateEmail(event.email);
      if (emailError != null) {
        emit(AuthError(message: emailError));
        return;
      }

      emit(const AuthLoading());

      await authRepository.sendPasswordResetEmail(email: event.email);

      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      logger.e('Error sending password reset: $e');
      final errorMessage = _getErrorMessage(e);
      emit(AuthError(message: errorMessage));
    }
  }

  /// Helper: Extract friendly error message from exception
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Check for custom exception messages
    if (errorString.contains('Email not registered')) {
      return 'Email not registered. Please sign up first.';
    }
    if (errorString.contains('Incorrect password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorString.contains('Email already')) {
      return 'This email is already registered. Please login instead.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Use uppercase, number, and special character.';
    }
    if (errorString.contains('network')) {
      return 'Network error. Check your internet connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('Google')) {
      return 'Google sign-in failed. Please try again.';
    }

    return error is Exception ? error.toString() : 'An error occurred. Please try again.';
  }
}
