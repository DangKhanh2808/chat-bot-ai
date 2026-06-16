import 'package:logger/logger.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../exceptions/auth_exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;
  final Logger _logger;

  // In-memory cache for current user
  User? _cachedUser;

  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    Logger? logger,
  })  : _authDataSource = authDataSource,
        _logger = logger ?? Logger();

  @override
  Future<bool> isUserAuthenticated() async {
    try {
      return await _authDataSource.isUserAuthenticated();
    } catch (e) {
      _logger.e('Error checking authentication: $e');
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Return cached user if available
      if (_cachedUser != null) {
        return _cachedUser;
      }

      // Fetch from datasource
      final userModel = await _authDataSource.getCurrentUser();
      if (userModel != null) {
        _cachedUser = userModel.toEntity();
        return _cachedUser;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _authDataSource.loginWithEmail(
        email: email,
        password: password,
      );

      final user = userModel.toEntity();
      _cachedUser = user;

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error logging in: $e');
      throw UnknownAuthException(message: 'Login failed: $e');
    }
  }

  @override
  Future<User> signupWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _authDataSource.signUpWithEmail(
        email: email,
        password: password,
      );

      final user = userModel.toEntity();
      _cachedUser = user;

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error signing up: $e');
      throw UnknownAuthException(message: 'Signup failed: $e');
    }
  }

  @override
  Future<User> loginWithGoogle() async {
    try {
      final userModel = await _authDataSource.loginWithGoogle();

      final user = userModel.toEntity();
      _cachedUser = user;

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error logging in with Google: $e');
      throw UnknownAuthException(message: 'Google login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authDataSource.logout();
      _cachedUser = null;
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error logging out: $e');
      throw UnknownAuthException(message: 'Logout failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email: email);
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Error sending password reset: $e');
      throw UnknownAuthException(message: 'Failed to send reset email: $e');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await _authDataSource.getAuthToken();
    } catch (e) {
      _logger.e('Error getting auth token: $e');
      return null;
    }
  }
}
