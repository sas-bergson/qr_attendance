import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/calendar_event.dart';

/// Service for fetching calendar events from the backend API
class CalendarService {
  /// Fetch events for a specific month
  ///
  /// Parameters:
  ///   - month: Month number (1-12)
  ///   - year: Year (e.g., 2026)
  ///   - userId: Optional user ID to filter events
  ///   - token: JWT authentication token
  ///
  /// Returns: CalendarEventsResponse with events grouped by day
  static Future<CalendarEventsResponse> getEventsForMonth({
    required int month,
    required int year,
    int? userId,
    required String token,
  }) async {
    try {
      final String url = _buildUrl(month, year, userId);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CalendarEventsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Invalid or expired token');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Invalid parameters');
      } else {
        throw Exception(
            'Failed to fetch calendar events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      rethrow;
    }
  }

  /// Fetch current month's events
  static Future<CalendarEventsResponse> getCurrentMonthEvents({
    required String token,
    int? userId,
  }) async {
    final now = DateTime.now();
    return getEventsForMonth(
      month: now.month,
      year: now.year,
      userId: userId,
      token: token,
    );
  }

  /// Fetch next month's events
  static Future<CalendarEventsResponse> getNextMonthEvents({
    required String token,
    int? userId,
  }) async {
    final now = DateTime.now();
    var month = now.month + 1;
    var year = now.year;

    if (month > 12) {
      month = 1;
      year += 1;
    }

    return getEventsForMonth(
      month: month,
      year: year,
      userId: userId,
      token: token,
    );
  }

  /// Fetch previous month's events
  static Future<CalendarEventsResponse> getPreviousMonthEvents({
    required String token,
    int? userId,
  }) async {
    final now = DateTime.now();
    var month = now.month - 1;
    var year = now.year;

    if (month < 1) {
      month = 12;
      year -= 1;
    }

    return getEventsForMonth(
      month: month,
      year: year,
      userId: userId,
      token: token,
    );
  }

  /// Build the full API URL with parameters
  static String _buildUrl(int month, int year, int? userId) {
    final baseUrl = AppConfig.apiUrl;
    var url = '$baseUrl/calendar/events?month=$month&year=$year';

    if (userId != null) {
      url += '&user_id=$userId';
    }

    return url;
  }

  /// Get event count for a specific day
  static int getEventCountForDay(
    CalendarEventsResponse response,
    int dayOfMonth,
  ) {
    final dayData = response.data.firstWhere(
      (day) => day.dayOfMonth == dayOfMonth,
      orElse: () => CalendarDayEvents(
        dayOfMonth: dayOfMonth,
        eventCount: 0,
        events: [],
      ),
    );

    return dayData.eventCount;
  }

  /// Get events for a specific day
  static List<CalendarEventDetail> getEventsForDay(
    CalendarEventsResponse response,
    int dayOfMonth,
  ) {
    final dayData = response.data.firstWhere(
      (day) => day.dayOfMonth == dayOfMonth,
      orElse: () => CalendarDayEvents(
        dayOfMonth: dayOfMonth,
        eventCount: 0,
        events: [],
      ),
    );

    return dayData.events;
  }

  /// Format event time for display
  static String formatEventTime(DateTime? startAt, DateTime? stopAt) {
    if (startAt == null) return 'TBA';

    final startTime =
        '${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}';

    if (stopAt == null) return startTime;

    final stopTime =
        '${stopAt.hour.toString().padLeft(2, '0')}:${stopAt.minute.toString().padLeft(2, '0')}';

    return '$startTime - $stopTime';
  }

  /// Get status badge color based on event status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'running':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get event type icon
  static IconData getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'class':
        return Icons.school;
      case 'meeting':
        return Icons.people;
      case 'seminar':
        return Icons.slideshow;
      default:
        return Icons.event;
    }
  }
}
