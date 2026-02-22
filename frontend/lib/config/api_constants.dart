/// API configuration constants
/// Centralized endpoint and configuration management
library;

class ApiConstants {
  /// Backend base URL - auto-detected or from config
  /// Update this based on your deployment environment
  static const String baseUrl = 'http://localhost:5000';

  // ============ Authentication Endpoints ============
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String verifyToken = '/api/v1/auth/verify';
  static const String profile = '/api/v1/auth/profile';

  // ============ Events Endpoints ============
  static const String getEvents = '/api/v1/events';
  static const String getEvent = '/api/v1/events/{id}';
  static const String createEvent = '/api/v1/events';
  static const String updateEvent = '/api/v1/events/{id}';
  static const String deleteEvent = '/api/v1/events/{id}';

  // ============ Attendance Endpoints ============
  static const String markAttendance = '/api/v1/attendance/mark';
  static const String getAttendance = '/api/v1/attendance';
  static const String getAttendanceRecord = '/api/v1/attendance/{id}';
  static const String getEventAttendance =
      '/api/v1/events/{eventId}/attendance';

  // ============ QR Code Endpoints ============
  static const String generateQr = '/api/v1/qr/generate';
  static const String validateQr = '/api/v1/qr/validate';

  // ============ User Endpoints ============
  static const String getUser = '/api/v1/users/{id}';
  static const String updateUser = '/api/v1/users/{id}';
  static const String getUserAttendance = '/api/v1/users/{id}/attendance';

  // ============ Department Endpoints ============
  static const String getDepartments = '/api/v1/departments';
  static const String getDepartment = '/api/v1/departments/{id}';

  // ============ Course Endpoints ============
  static const String getCourses = '/api/v1/courses';
  static const String getCourse = '/api/v1/courses/{id}';
  static const String getCourseDepartment =
      '/api/v1/departments/{deptId}/courses';

  // ============ Request Timeouts ============
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============ Headers ============
  static const Map<String, String> commonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ Token Storage Keys ============
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String tokenExpiryKey = 'token_expiry';
}
