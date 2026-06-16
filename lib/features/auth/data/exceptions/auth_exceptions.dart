/// Base exception for all auth-related errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// User not found in Firebase
class UserNotFoundException extends AuthException {
  UserNotFoundException({String message = 'User not found'})
      : super(message: message, code: 'user-not-found');
}

/// Email already in use
class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException({String message = 'Email already in use'})
      : super(message: message, code: 'email-already-in-use');
}

/// Password is too weak
class WeakPasswordException extends AuthException {
  WeakPasswordException({
    String message = 'Password must be at least 8 characters with uppercase, number, and special character',
  }) : super(message: message, code: 'weak-password');
}

/// Invalid credentials (wrong password)
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException({String message = 'Invalid email or password'})
      : super(message: message, code: 'invalid-credentials');
}

/// Network connectivity error
class NetworkException extends AuthException {
  NetworkException({String message = 'Network error. Please check your connection'})
      : super(message: message, code: 'network-error');
}

/// Operation timed out
class TimeoutException extends AuthException {
  TimeoutException({String message = 'Request timed out. Please try again'})
      : super(message: message, code: 'timeout');
}

/// Google Sign-in specific error
class GoogleSignInException extends AuthException {
  GoogleSignInException({String message = 'Google Sign-in failed'})
      : super(message: message, code: 'google-signin-error');
}

/// Unknown error from Firebase
class UnknownAuthException extends AuthException {
  UnknownAuthException({String message = 'An unexpected error occurred'})
      : super(message: message, code: 'unknown-error');
}
