/// Custom exception classes for API operations
/// Provides structured error handling across the application
library;

/// Base exception for all API-related errors
abstract class ApiException implements Exception {
  final String message;
  final String? details;

  ApiException({
    required this.message,
    this.details,
  });

  @override
  String toString() => details != null ? '$message\n$details' : message;
}

/// Network connectivity issues
/// - No internet connection
/// - Network timeout
/// - Socket exceptions
class NetworkException extends ApiException {
  NetworkException({
    super.message = 'Network error. Please check your connection.',
    super.details,
  });
}

/// Authentication failures
/// - Invalid credentials
/// - Token expired
/// - Unauthorized access
class AuthException extends ApiException {
  AuthException({
    super.message = 'Authentication failed.',
    super.details,
  });
}

/// Token refresh failures
/// - Refresh token invalid
/// - Session expired
/// - Cannot refresh automatically
class TokenRefreshException extends ApiException {
  TokenRefreshException({
    super.message = 'Session expired. Please login again.',
    super.details,
  });
}

/// Validation errors
/// - Invalid request data
/// - Missing required fields
/// - Invalid format
class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({
    super.message = 'Validation error.',
    this.errors,
    super.details,
  });
}

/// Server errors
/// - 500 Internal Server Error
/// - 503 Service Unavailable
/// - Unexpected server response
class ServerException extends ApiException {
  final int? statusCode;

  ServerException({
    super.message = 'Server error. Please try again later.',
    this.statusCode,
    super.details,
  });
}

/// Not found errors
/// - 404 Resource not found
class NotFoundException extends ApiException {
  NotFoundException({
    super.message = 'Resource not found.',
    super.details,
  });
}

/// Conflict errors
/// - 409 Conflict
/// - Duplicate resource
class ConflictException extends ApiException {
  ConflictException({
    super.message = 'Resource already exists.',
    super.details,
  });
}

/// Bad request errors
/// - 400 Bad Request
/// - Malformed request
class BadRequestException extends ApiException {
  BadRequestException({
    super.message = 'Invalid request.',
    super.details,
  });
}

/// Rate limit exceeded
/// - 429 Too Many Requests
class RateLimitException extends ApiException {
  final int? retryAfterSeconds;

  RateLimitException({
    super.message = 'Too many requests. Please try again later.',
    this.retryAfterSeconds,
    super.details,
  });
}

/// Generic/unknown API error
class UnknownApiException extends ApiException {
  UnknownApiException({
    super.message = 'An unexpected error occurred.',
    super.details,
  });
}
