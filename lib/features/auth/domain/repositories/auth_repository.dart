import '../entities/user.dart';

abstract class AuthRepository {
  /// Check if user is currently authenticated
  Future<bool> isUserAuthenticated();

  /// Get current authenticated user
  Future<User?> getCurrentUser();

  /// Login with email and password
  /// Throws [AuthException] on failure
  Future<User> loginWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  /// Creates user in Firebase Auth and Firestore
  /// Throws [AuthException] on failure
  Future<User> signupWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  /// Throws [AuthException] on failure
  Future<User> loginWithGoogle();

  /// Logout current user
  /// Throws [AuthException] on failure
  Future<void> logout();

  /// Send password reset email
  /// Throws [AuthException] if email not found or network error
  Future<void> sendPasswordResetEmail({required String email});

  /// Get current authentication token
  Future<String?> getAuthToken();
}
