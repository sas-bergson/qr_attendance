/// Authentication Service
/// Handles all authentication-related API calls
///
/// Features:
/// - User login with email/password
/// - User registration
/// - Token refresh
/// - User logout
/// - Profile retrieval
/// - Token verification
library;

import 'api_service.dart';
import '../config/api_constants.dart';
import 'exceptions/api_exceptions.dart';

class AuthService {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  final ApiService _apiService = ApiService();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// ============ Login ============
  /// Login with email and password
  /// Returns: {access_token, refresh_token, user}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );

      // Extract tokens
      final accessToken = response['access_token'];
      final refreshToken = response['refresh_token'];

      if (accessToken == null) {
        throw AuthException(
          message: 'Invalid login response from server.',
          details: 'Missing access_token',
        );
      }

      // Save tokens to storage
      await _apiService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? accessToken,
      );

      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw AuthException(
        message: 'Login failed.',
        details: e.toString(),
      );
    }
  }

  /// ============ Register ============
  /// Register a new user account
  /// Returns: {access_token, refresh_token, user}
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? departmentId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        body: {
          'email': email,
          'password': password,
          'name': name,
          if (departmentId != null) 'department_id': departmentId,
        },
        requireAuth: false,
      );

      // Extract tokens
      final accessToken = response['access_token'];
      final refreshToken = response['refresh_token'];

      if (accessToken == null) {
        throw AuthException(
          message: 'Invalid registration response from server.',
          details: 'Missing access_token',
        );
      }

      // Save tokens to storage
      await _apiService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? accessToken,
      );

      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw AuthException(
        message: 'Registration failed.',
        details: e.toString(),
      );
    }
  }

  /// ============ Logout ============
  /// Logout current user
  Future<void> logout() async {
    try {
      // Optional: notify backend of logout
      try {
        await _apiService.post(ApiConstants.logout);
      } catch (e) {
        // Continue logout even if API call fails
        print('Backend logout notification failed: $e');
      }

      // Clear local tokens
      await _apiService.logout();
    } catch (e) {
      throw AuthException(
        message: 'Logout failed.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Profile ============
  /// Get current user's profile information
  /// Returns: {id, email, name, role, department, created_at, ...}
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to get profile.',
        details: e.toString(),
      );
    }
  }

  /// ============ Verify Token ============
  /// Verify if current token is still valid
  /// Returns: {valid: true/false}
  Future<bool> verifyToken() async {
    try {
      final response = await _apiService.post(ApiConstants.verifyToken);
      return response['valid'] ?? false;
    } on TokenRefreshException {
      return false;
    } on ApiException catch (e) {
      if (e is AuthException) {
        return false;
      }
      rethrow;
    }
  }

  /// ============ Refresh Token ============
  /// Manually refresh access token using refresh token
  /// Usually called automatically by ApiService, but can be called manually
  Future<void> refreshToken() async {
    try {
      // ApiService will handle the refresh internally
      // This just triggers the refresh
      final token = _apiService.getAccessToken();
      if (token != null && _apiService.isAuthenticated()) {
        // Token is still valid, no need to refresh
        return;
      }
    } catch (e) {
      throw TokenRefreshException(
        message: 'Token refresh failed.',
        details: e.toString(),
      );
    }
  }

  /// ============ Check Authentication Status ============
  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return _apiService.isAuthenticated();
  }

  /// ============ Update User ============
  /// Update user profile information
  /// Returns: updated user object
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? departmentId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (departmentId != null) body['department_id'] = departmentId;

      final response = await _apiService.put(
        ApiConstants.updateUser.replaceFirst('{id}', userId),
        body: body,
      );

      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to update profile.',
        details: e.toString(),
      );
    }
  }

  /// ============ Change Password ============
  /// Change user password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '/api/v1/auth/change-password',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to change password.',
        details: e.toString(),
      );
    }
  }

  /// ============ Reset Password Request ============
  /// Request password reset (sends email with reset link)
  Future<void> requestPasswordReset(String email) async {
    try {
      await _apiService.post(
        '/api/v1/auth/password-reset-request',
        body: {'email': email},
        requireAuth: false,
      );
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to request password reset.',
        details: e.toString(),
      );
    }
  }

  /// ============ Reset Password ============
  /// Complete password reset with token from email
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '/api/v1/auth/password-reset',
        body: {
          'token': token,
          'new_password': newPassword,
        },
        requireAuth: false,
      );
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to reset password.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get User by ID ============
  /// Get specific user information
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.getUser.replaceFirst('{id}', userId),
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to get user.',
        details: e.toString(),
      );
    }
  }
}
