import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated on app startup
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

/// User attempts to login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// User attempts to sign up with email and password
class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String confirmPassword;

  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword];
}

/// User attempts to sign in with Google
class AuthGoogleSigninRequested extends AuthEvent {
  const AuthGoogleSigninRequested();
}

/// User attempts to logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// User requests password reset email
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
