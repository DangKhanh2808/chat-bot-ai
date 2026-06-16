import '../models/user_model.dart';

/// Abstract interface for Firebase Auth operations
abstract class FirebaseAuthDataSource {
  /// Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Login with email and password
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<UserModel> loginWithGoogle();

  /// Get currently logged-in user
  Future<UserModel?> getCurrentUser();

  /// Logout
  Future<void> logout();

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email});

  /// Get current auth token
  Future<String?> getAuthToken();

  /// Check if user is authenticated
  Future<bool> isUserAuthenticated();

  /// Create user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  });

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  });

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile({required String userId});
}
