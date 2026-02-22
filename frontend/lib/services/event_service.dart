/// Event Service
/// Handles all event-related API calls
///
/// Features:
/// - Fetch all events
/// - Fetch event details
/// - Create events (admin)
/// - Update events (admin)
/// - Delete events (admin)
/// - Get event attendance
/// - Filter and search events
library;

import 'api_service.dart';
import '../config/api_constants.dart';
import 'exceptions/api_exceptions.dart';

class EventService {
  /// Singleton instance
  static final EventService _instance = EventService._internal();

  final ApiService _apiService = ApiService();

  factory EventService() {
    return _instance;
  }

  EventService._internal();

  /// ============ Get All Events ============
  /// Fetch list of all events with optional filtering
  /// Returns: List of event objects
  Future<List<Map<String, dynamic>>> getEvents({
    int? limit,
    int? offset,
    String? status,
    String? departmentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (status != null) queryParams['status'] = status;
      if (departmentId != null) queryParams['department_id'] = departmentId;

      // Build query string
      String endpoint = ApiConstants.getEvents;
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await _apiService.get(endpoint);

      // Handle both array and object responses
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['events'] != null) {
        return List<Map<String, dynamic>>.from(response['events']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch events.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Event Details ============
  /// Fetch details for a specific event
  /// Returns: Event object with full details
  Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.getEvent.replaceFirst('{id}', eventId),
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch event details.',
        details: e.toString(),
      );
    }
  }

  /// ============ Create Event ============
  /// Create a new event (admin only)
  /// Returns: Created event object
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String courseId,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? qrCode,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createEvent,
        body: {
          'title': title,
          'description': description,
          'course_id': courseId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          if (location != null) 'location': location,
          if (qrCode != null) 'qr_code': qrCode,
        },
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to create event.',
        details: e.toString(),
      );
    }
  }

  /// ============ Update Event ============
  /// Update an existing event (admin only)
  /// Returns: Updated event object
  Future<Map<String, dynamic>> updateEvent(
    String eventId, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (startTime != null) body['start_time'] = startTime.toIso8601String();
      if (endTime != null) body['end_time'] = endTime.toIso8601String();
      if (location != null) body['location'] = location;
      if (status != null) body['status'] = status;

      final response = await _apiService.put(
        ApiConstants.updateEvent.replaceFirst('{id}', eventId),
        body: body,
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to update event.',
        details: e.toString(),
      );
    }
  }

  /// ============ Delete Event ============
  /// Delete an event (admin only)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiService.delete(
        ApiConstants.deleteEvent.replaceFirst('{id}', eventId),
      );
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to delete event.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Event Attendance ============
  /// Get attendance records for a specific event
  /// Returns: List of attendance records
  Future<List<Map<String, dynamic>>> getEventAttendance(
    String eventId, {
    int? limit,
    int? offset,
  }) async {
    try {
      String endpoint =
          ApiConstants.getEventAttendance.replaceFirst('{eventId}', eventId);

      // Add query parameters
      if (limit != null || offset != null) {
        final params = <String>[];
        if (limit != null) params.add('limit=$limit');
        if (offset != null) params.add('offset=$offset');
        endpoint = '$endpoint?${params.join('&')}';
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
        message: 'Failed to fetch event attendance.',
        details: e.toString(),
      );
    }
  }

  /// ============ Search Events ============
  /// Search events by title or description
  /// Returns: List of matching events
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      String endpoint = '${ApiConstants.getEvents}?search=$query';

      final response = await _apiService.get(endpoint);

      // Handle different response formats
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response['events'] != null) {
        return List<Map<String, dynamic>>.from(response['events']);
      } else if (response is Map && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to search events.',
        details: e.toString(),
      );
    }
  }

  /// ============ Get Upcoming Events ============
  /// Get list of upcoming events
  /// Returns: List of future events
  Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int limit = 10,
  }) async {
    try {
      return await getEvents(
        limit: limit,
        status: 'upcoming',
      );
    } on ApiException rethrow {
      rethrow;
    }
  }

  /// ============ Get Events by Department ============
  /// Get all events for a specific department
  /// Returns: List of department events
  Future<List<Map<String, dynamic>>> getEventsByDepartment(
    String departmentId, {
    int? limit,
  }) async {
    try {
      return await getEvents(
        limit: limit,
        departmentId: departmentId,
      );
    } on ApiException rethrow {
      rethrow;
    }
  }

  /// ============ Get Event Statistics ============
  /// Get attendance statistics for an event
  /// Returns: Event statistics object
  Future<Map<String, dynamic>> getEventStatistics(String eventId) async {
    try {
      final response = await _apiService.get(
        '/api/v1/events/$eventId/statistics',
      );
      return response;
    } on ApiException rethrow {
      rethrow;
    } catch (e) {
      throw UnknownApiException(
        message: 'Failed to fetch event statistics.',
        details: e.toString(),
      );
    }
  }

  /// ============ Generate QR Code for Event ============
  /// Generate QR code for event attendance marking
  /// Returns: QR code data/image
  Future<Map<String, dynamic>> generateQrForEvent(String eventId) async {
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
