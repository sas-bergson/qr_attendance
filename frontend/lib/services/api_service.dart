/// Base API Service
/// Handles all HTTP requests, JWT token management, and automatic token refresh
/// 
/// This is the core service that all other services depend on.
/// It manages:
/// - HTTP client configuration
/// - JWT token storage and refresh
/// - Automatic retry on 401 (unauthorized)
/// - Error handling and conversion
/// - Request/response logging
library;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'dart:async';

import '../config/app_config.dart';
import '../config/api_constants.dart';
import 'exceptions/api_exceptions.dart';

class ApiService {
  /// Singleton instance
  static final ApiService _instance = ApiService._internal();

  /// Private storage references
  late SharedPreferences _prefs;

  /// HTTP client
  late http.Client _client;

  /// Access token
  String? _accessToken;

  /// Refresh token
  String? _refreshToken;

  /// Lock for token refresh to prevent multiple simultaneous refreshes
  final _tokenRefreshLock = Completer<void>();

  /// Debug mode - set to true for verbose logging
  bool _debugMode = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _client = http.Client();
  }

  /// Initialize the API service with stored tokens
  /// Call this in main() or app initialization
  Future<void> initialize({bool debugMode = false}) async {
    _debugMode = debugMode;
    _prefs = await SharedPreferences.getInstance();

    // Load stored tokens
    _accessToken = _prefs.getString(ApiConstants.accessTokenKey);
    _refreshToken = _prefs.getString(ApiConstants.refreshTokenKey);

    _log('API Service initialized');
    _log('Access Token: ${_accessToken != null ? '***' : 'null'}');
  }

  /// ============ GET Request ============
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _request(
      'GET',
      endpoint,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// ============ POST Request ============
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _request(
      'POST',
      endpoint,
      body: body,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// ============ PUT Request ============
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _request(
      'PUT',
      endpoint,
      body: body,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// ============ DELETE Request ============
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _request(
      'DELETE',
      endpoint,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// ============ Core Request Method ============
  Future<dynamic> _request(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    try {
      // Validate token if authentication required
      if (requireAuth) {
        await _ensureValidToken();
      }

      // Build URL
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      // Prepare headers
      final requestHeaders = _buildHeaders(headers, requireAuth);

      // Log request
      _log('📤 $method $endpoint');
      if (body != null) {
        _log('   Body: ${jsonEncode(body)}');
      }

      // Make request based on method
      http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(url, headers: requestHeaders)
              .timeout(ApiConstants.connectTimeout);
          break;
        case 'POST':
          response = await _client
              .post(
                url,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConstants.connectTimeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                url,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConstants.connectTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(url, headers: requestHeaders)
              .timeout(ApiConstants.connectTimeout);
          break;
        default:
          throw UnknownApiException(details: 'Unknown HTTP method: $method');
      }

      // Log response
      _log('📥 Status: ${response.statusCode}');
      _log('   Body: ${response.body}');

      // Handle response
      return _handleResponse(response, method, endpoint, body, headers, requireAuth);
    } on SocketException catch (e) {
      _log('❌ Network Error: $e');
      throw NetworkException(details: e.toString());
    } on TimeoutException catch (e) {
      _log('❌ Timeout Error: $e');
      throw NetworkException(
        message: 'Request timeout. Please check your connection.',
        details: e.toString(),
      );
    } on ApiException rethrow {
      // API exceptions are already processed
      rethrow;
    } catch (e) {
      _log('❌ Unknown Error: $e');
      throw UnknownApiException(details: e.toString());
    }
  }

  /// ============ Response Handler ============
  dynamic _handleResponse(
    http.Response response,
    String method,
    String endpoint,
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth,
  ) {
    final statusCode = response.statusCode;

    // Parse response body
    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (e) {
      responseBody = response.body;
    }

    // Handle status codes
    if (statusCode >= 200 && statusCode < 300) {
      // Success
      return responseBody;
    } else if (statusCode == 400) {
      // Bad Request
      final message = _extractErrorMessage(responseBody, 'Invalid request');
      throw BadRequestException(
        message: message,
        details: responseBody.toString(),
      );
    } else if (statusCode == 401) {
      // Unauthorized - try to refresh token
      _log('⚠️ Token expired (401), attempting refresh...');
      try {
        return _handleUnauthorized(method, endpoint, body, headers, requireAuth);
      } catch (e) {
        _log('❌ Token refresh failed: $e');
        throw AuthException(
          message: 'Session expired. Please login again.',
          details: e.toString(),
        );
      }
    } else if (statusCode == 403) {
      // Forbidden
      throw AuthException(
        message: 'Access denied.',
        details: responseBody.toString(),
      );
    } else if (statusCode == 404) {
      // Not Found
      final message = _extractErrorMessage(responseBody, 'Resource not found');
      throw NotFoundException(message: message);
    } else if (statusCode == 409) {
      // Conflict
      final message = _extractErrorMessage(responseBody, 'Resource already exists');
      throw ConflictException(message: message);
    } else if (statusCode == 422) {
      // Validation Error
      final message = _extractErrorMessage(responseBody, 'Validation failed');
      throw ValidationException(
        message: message,
        details: responseBody.toString(),
      );
    } else if (statusCode == 429) {
      // Rate Limited
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '60');
      throw RateLimitException(retryAfterSeconds: retryAfter);
    } else if (statusCode >= 500) {
      // Server Error
      final message = _extractErrorMessage(responseBody, 'Server error');
      throw ServerException(
        message: message,
        statusCode: statusCode,
        details: responseBody.toString(),
      );
    } else {
      // Unknown error
      throw UnknownApiException(
        message: 'Unexpected response status: $statusCode',
        details: responseBody.toString(),
      );
    }
  }

  /// ============ Token Management ============

  /// Ensure access token is valid, refresh if needed
  Future<void> _ensureValidToken() async {
    if (_accessToken == null) {
      throw TokenRefreshException(message: 'Not authenticated. Please login.');
    }

    // Check if token is expired
    if (_isTokenExpired(_accessToken!)) {
      _log('⚠️ Token expired, refreshing...');
      await _refreshAccessToken();
    }
  }

  /// Refresh access token using refresh token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw TokenRefreshException(message: 'No refresh token available.');
    }

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}');
      final response = await _client
          .post(
            url,
            headers: ApiConstants.commonHeaders,
            body: jsonEncode({'refresh_token': _refreshToken}),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'] ?? data['token'];
        _refreshToken = data['refresh_token'] ?? _refreshToken;

        // Store new tokens
        await _prefs.setString(ApiConstants.accessTokenKey, _accessToken!);
        if (data['refresh_token'] != null) {
          await _prefs.setString(ApiConstants.refreshTokenKey, _refreshToken!);
        }

        _log('✅ Token refreshed successfully');
      } else {
        throw TokenRefreshException(
          message: 'Failed to refresh token.',
          details: response.body,
        );
      }
    } catch (e) {
      _log('❌ Token refresh error: $e');
      await logout();
      throw TokenRefreshException(
        message: 'Session expired. Please login again.',
        details: e.toString(),
      );
    }
  }

  /// Handle 401 Unauthorized - retry request after token refresh
  Future<dynamic> _handleUnauthorized(
    String method,
    String endpoint,
    dynamic body,
    Map<String, String>? headers,
    bool requireAuth,
  ) async {
    // Wait for token refresh to complete (prevent multiple refreshes)
    if (!_tokenRefreshLock.isCompleted) {
      await _tokenRefreshLock.future;
    } else {
      await _refreshAccessToken();
    }

    // Retry the original request
    _log('🔄 Retrying $method $endpoint after token refresh');
    return _request(
      method,
      endpoint,
      body: body,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// Check if token is expired
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      _log('⚠️ Could not check token expiration: $e');
      return true; // Assume expired if we can't check
    }
  }

  /// ============ Token Storage ============

  /// Save tokens to storage
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await Future.wait([
      _prefs.setString(ApiConstants.accessTokenKey, accessToken),
      _prefs.setString(ApiConstants.refreshTokenKey, refreshToken),
    ]);

    _log('✅ Tokens saved');
  }

  /// Clear tokens from storage
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    await Future.wait([
      _prefs.remove(ApiConstants.accessTokenKey),
      _prefs.remove(ApiConstants.refreshTokenKey),
    ]);

    _log('✅ Tokens cleared');
  }

  /// Get current access token (for debugging)
  String? getAccessToken() => _accessToken;

  /// Check if user is authenticated
  bool isAuthenticated() => _accessToken != null && !_isTokenExpired(_accessToken!);

  /// Logout
  Future<void> logout() async {
    await clearTokens();
    _log('✅ User logged out');
  }

  /// ============ Helper Methods ============

  /// Build request headers with authentication
  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requireAuth,
  ) {
    final headers = Map<String, String>.from(ApiConstants.commonHeaders);

    // Add authorization header if token exists
    if (requireAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Override with custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Extract error message from response
  String _extractErrorMessage(dynamic response, String defaultMessage) {
    try {
      if (response is Map) {
        // Try common error field names
        return response['message'] ??
            response['error'] ??
            response['detail'] ??
            response['msg'] ??
            defaultMessage;
      }
      return defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }

  /// Debug logging
  void _log(String message) {
    if (_debugMode) {
      print('[API Service] $message');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
