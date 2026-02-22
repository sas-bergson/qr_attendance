/// Attendance Service
/// Handles all attendance-related API calls
///
/// Features:
/// - Mark attendance via QR code
/// - Get attendance records
/// - Get user attendance history
/// - Get attendance statistics
/// - Validate QR codes
/// - Generate QR codes for events
library;

import 'api_service.dart';
import '../config/api_constants.dart';
import 'exceptions/api_exceptions.dart';

class AttendanceService {
  /// Singleton instance
  static final AttendanceService _instance = AttendanceService._internal();

  final ApiService _apiService = ApiService();

  factory AttendanceService() {
    return _instance;
  }

  AttendanceService._internal();

  /// ============ Mark Attendance ============
  /// Mark attendance by scanning QR code
  /// Returns: Attendance record object
  Future<Map<String, dynamic>> markAttendance({
    required String eventId,
    required String qrCodeData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.markAttendance,
        body: {
          'event_id': eventId,
          'qr_code': qrCodeData,
        },
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to mark attendance.',
        details: e.toString(),
      );
    }
  }

  /// ============ Validate QR Code ============
  /// Validate QR code before marking attendance
  /// Returns: Validation result with event details
  Future<Map<String, dynamic>> validateQrCode(String qrCodeData) async {
    try {
      final response = await _apiService.post(
        ApiConstants.validateQr,
        body: {'qr_code': qrCodeData},
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to validate QR code.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get User Attendance ============
  /// Get all attendance records for current user
  /// Returns: List of attendance records
  Future<List<Map<String, dynamic>>> getUserAttendance({
    int? limit,
    int? offset,
    String? status,
  }) async {
    try {
      String endpoint = ApiConstants.getAttendance;

      // Build query parameters
      final queryParams = <String>[];
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      if (status != null) queryParams.add('status=$status');

      if (queryParams.isNotEmpty) {
        endpoint = '$endpoint?${queryParams.join('&')}';
      }

      final response = await _apiService.get(endpoint);

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['attendance'] != null) {
        return List<Map<String, dynamic>>.from(response['attendance']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch attendance records.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Specific Attendance Record ============
  /// Get details for a specific attendance record
  /// Returns: Attendance record object
  Future<Map<String, dynamic>> getAttendanceRecord(String attendanceId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.getAttendanceRecord.replaceFirst('{id}', attendanceId),
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch attendance record.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get User Attendance by User ID ============
  /// Get attendance records for a specific user (admin)
  /// Returns: List of user's attendance records
  Future<List<Map<String, dynamic>>> getUserAttendanceById(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      String endpoint =
          ApiConstants.getUserAttendance.replaceFirst('{id}', userId);

      // Add query parameters
      final queryParams = <String>[];
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');

      if (queryParams.isNotEmpty) {
        endpoint = '$endpoint?${queryParams.join('&')}';
      }

      final response = await _apiService.get(endpoint);

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['attendance'] != null) {
        return List<Map<String, dynamic>>.from(response['attendance']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch user attendance.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Today's Attendance ============
  /// Get current user's attendance for today
  /// Returns: List of today's attendance records
  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    try {
      String endpoint = '${ApiConstants.getAttendance}?date=today';
      final response = await _apiService.get(endpoint);

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['attendance'] != null) {
        return List<Map<String, dynamic>>.from(response['attendance']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch today\'s attendance.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Attendance by Date Range ============
  /// Get attendance records within a date range
  /// Returns: List of attendance records
  Future<List<Map<String, dynamic>>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    try {
      String endpoint = ApiConstants.getAttendance;
      final queryParams = <String>[
        'start_date=${startDate.toIso8601String()}',
        'end_date=${endDate.toIso8601String()}',
      ];

      if (limit != null) queryParams.add('limit=$limit');

      endpoint = '$endpoint?${queryParams.join('&')}';
      final response = await _apiService.get(endpoint);

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['attendance'] != null) {
        return List<Map<String, dynamic>>.from(response['attendance']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch attendance records.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Attendance Statistics ============
  /// Get attendance statistics for user or event
  /// Returns: Statistics object with counts and percentages
  Future<Map<String, dynamic>> getAttendanceStatistics({
    String? userId,
    String? eventId,
  }) async {
    try {
      String endpoint = '/api/v1/attendance/statistics';
      final queryParams = <String>[];

      if (userId != null) queryParams.add('user_id=$userId');
      if (eventId != null) queryParams.add('event_id=$eventId');

      if (queryParams.isNotEmpty) {
        endpoint = '$endpoint?${queryParams.join('&')}';
      }

      final response = await _apiService.get(endpoint);
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch attendance statistics.',
        details: e.toString(),
      );
    }
  }

  /// ============ Export Attendance ============
  /// Export attendance records as CSV or JSON
  /// Returns: Exported data
  Future<String> exportAttendance({
    String? eventId,
    String format = 'csv', // csv, json, xlsx
  }) async {
    try {
      String endpoint = '/api/v1/attendance/export?format=$format';
      if (eventId != null) endpoint += '&event_id=$eventId';

      final response = await _apiService.get(endpoint);
      return response.toString();
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to export attendance.',
        details: e.toString(),
      );
    }
  }

  /// ============ Bulk Mark Attendance ============
  /// Mark attendance for multiple users (admin)
  /// Returns: List of marked attendance records
  Future<List<Map<String, dynamic>>> bulkMarkAttendance({
    required String eventId,
    required List<String> userIds,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/v1/attendance/bulk-mark',
        body: {
          'event_id': eventId,
          'user_ids': userIds,
        },
      );

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['attendance'] != null) {
        return List<Map<String, dynamic>>.from(response['attendance']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to mark attendance in bulk.',
        details: e.toString(),
      );
    }
  }

  /// ============ Generate QR Code ============
  /// Generate QR code for event
  /// Returns: QR code data
  Future<Map<String, dynamic>> generateQrCode(String eventId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.generateQr,
        body: {'event_id': eventId},
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to generate QR code.',
        details: e.toString(),
      );
    }
  }
}
