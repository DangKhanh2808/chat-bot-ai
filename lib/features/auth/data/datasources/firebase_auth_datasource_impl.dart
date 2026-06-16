import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../exceptions/auth_exceptions.dart';
import '../models/user_model.dart';
import 'firebase_auth_datasource.dart';

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  @override
  Future<bool> isUserAuthenticated() async {
    try {
      return _firebaseAuth.currentUser != null;
    } catch (e) {
      _logger.e('Error checking authentication: $e');
      return false;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final profile = await getUserProfile(userId: firebaseUser.uid);
      return profile;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw UnknownAuthException(message: 'Login failed: No user returned');
      }

      // Get or create user profile
      final userProfile = await getUserProfile(userId: firebaseUser.uid);
      if (userProfile == null) {
        // Create new profile if doesn't exist
        await createUserProfile(
          userId: firebaseUser.uid,
          userData: {
            'id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'displayName': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoURL,
            'createdAt': DateTime.now().toIso8601String(),
            'isEmailVerified': firebaseUser.emailVerified,
            'lastLoginAt': DateTime.now().toIso8601String(),
          },
        );
      }

      // Update last login time
      await updateUserProfile(
        userId: firebaseUser.uid,
        userData: {
          'lastLoginAt': DateTime.now().toIso8601String(),
        },
      );

      return userProfile ?? _firebaseUserToModel(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Firebase auth error during login: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Unexpected error during login: $e');
      throw UnknownAuthException(message: 'Login failed: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw UnknownAuthException(message: 'Signup failed: No user returned');
      }

      // Create user profile in Firestore
      await createUserProfile(
        userId: firebaseUser.uid,
        userData: {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'displayName': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
          'createdAt': DateTime.now().toIso8601String(),
          'isEmailVerified': firebaseUser.emailVerified,
          'lastLoginAt': DateTime.now().toIso8601String(),
        },
      );

      return _firebaseUserToModel(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Firebase auth error during signup: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Unexpected error during signup: $e');
      throw UnknownAuthException(message: 'Signup failed: $e');
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      // TODO: Implement Google Sign-in
      // This requires google_sign_in package to be added
      throw UnknownAuthException(
        message: 'Google Sign-in not yet implemented. Add google_sign_in package.',
      );
    } catch (e) {
      _logger.e('Error during Google signin: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw GoogleSignInException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout: $e');
      throw UnknownAuthException(message: 'Logout failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Firebase error sending reset email: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      throw UnknownAuthException(message: 'Failed to send reset email: $e');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }
      return await user.getIdToken();
    } catch (e) {
      _logger.e('Error getting auth token: $e');
      return null;
    }
  }

  @override
  Future<void> createUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
      _logger.i('User profile created for $userId');
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      throw UnknownAuthException(message: 'Failed to create user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
      _logger.i('User profile updated for $userId');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw UnknownAuthException(message: 'Failed to update user profile: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile({required String userId}) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromJson(doc.data() ?? {});
    } catch (e) {
      _logger.e('Error getting user profile: $e');
      return null;
    }
  }

  /// Helper: Convert Firebase User to UserModel
  UserModel _firebaseUserToModel(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isEmailVerified: user.emailVerified,
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  /// Helper: Map Firebase auth exceptions to custom exceptions
  AuthException _mapFirebaseException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return UserNotFoundException(message: 'No account found with this email');
      case 'wrong-password':
        return InvalidCredentialsException(message: 'Incorrect password');
      case 'invalid-email':
        return InvalidCredentialsException(message: 'Invalid email format');
      case 'weak-password':
        return WeakPasswordException();
      case 'email-already-in-use':
        return EmailAlreadyInUseException(
          message: 'An account with this email already exists',
        );
      case 'network-request-failed':
      case 'service-disabled':
        return NetworkException();
      case 'too-many-requests':
        return NetworkException(message: 'Too many login attempts. Try again later');
      case 'operation-not-allowed':
        return UnknownAuthException(message: 'This authentication method is not enabled');
      default:
        return UnknownAuthException(
          message: 'Authentication error: ${e.message ?? e.code}',
        );
    }
  }
}
