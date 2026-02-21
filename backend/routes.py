from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import Database, dict_from_cursor

api = Blueprint('api', __name__, url_prefix='/api/v1')


@api.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint - no authentication required
    ---
    responses:
      200:
        description: API is healthy
        schema:
          type: object
          properties:
            status:
              type: string
              example: "ok"
            database:
              type: string
              example: "connected"
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("SELECT 1")
        return jsonify({
            'status': 'ok',
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'error',
            'database': 'disconnected',
            'error': str(e)
        }), 503


@api.route('/departments', methods=['GET'])
@jwt_required()
def get_departments():
    """
    Get all departments with statistics
    ---
    security:
      - Bearer: []
    responses:
      200:
        description: List of all departments with their statistics
        schema:
          type: array
          items:
            type: object
            properties:
              department_name:
                type: string
                example: "Software Engineering"
              total_courses:
                type: integer
                example: 3
              total_events:
                type: integer
                example: 15
              total_students:
                type: integer
                example: 15
              total_registrations:
                type: integer
                example: 225
              attendance_rate:
                type: string
                example: "85.93"
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    statistics.department_name,
                    statistics.total_courses,
                    statistics.total_events,
                    statistics.total_students,
                    statistics.total_registrations,
                    statistics.attendance_rate
                FROM department d
                CROSS JOIN LATERAL get_department_statistics(d.id) AS statistics
                ORDER BY statistics.department_name;
            """)
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/department/<int:dept_id>/courses', methods=['GET'])
@jwt_required()
def get_courses_by_department(dept_id):
    """
    Get all courses for a specific department
    ---
    security:
      - Bearer: []
    parameters:
      - name: dept_id
        in: path
        type: integer
        required: true
        description: Department ID
    responses:
      200:
        description: List of courses in the department
        schema:
          type: array
          items:
            type: object
      401:
        description: Unauthorized - Missing or invalid authentication token
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    course_id,
                    department_name,
                    course_code,
                    course_title,
                    event_count
                FROM get_courses_by_department(%s)
                ORDER BY course_code;
            """, (dept_id,))
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/course/<int:course_id>/events', methods=['GET'])
@jwt_required()
def get_events_by_course(course_id):
    """
    Get all events for a specific course
    ---
    security:
      - Bearer: []
    parameters:
      - name: course_id
        in: path
        type: integer
        required: true
        description: Course ID
    responses:
      200:
        description: List of events in the course
        schema:
          type: array
          items:
            type: object
      401:
        description: Unauthorized - Missing or invalid authentication token
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    event_id,
                    course_code,
                    course_title,
                    event_name,
                    event_type,
                    event_status,
                    start_at,
                    organizer_name,
                    registration_count,
                    present_count,
                    absent_count,
                    late_count
                FROM get_events_by_course(%s)
                ORDER BY start_at;
            """, (course_id,))
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/event/<int:event_id>/registrations', methods=['GET'])
@jwt_required()
def get_registrations_by_event(event_id):
    """
    Get all registrations for a specific event
    ---
    security:
      - Bearer: []
    parameters:
      - name: event_id
        in: path
        type: integer
        required: true
        description: Event ID
    responses:
      200:
        description: List of registrations for the event
        schema:
          type: array
          items:
            type: object
      401:
        description: Unauthorized - Missing or invalid authentication token
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    student_name,
                    student_email,
                    registration_status,
                    attendance_status,
                    scanned_at
                FROM get_registrations_by_event(%s)
                ORDER BY student_name;
            """, (event_id,))
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/course/<int:course_id>/statistics', methods=['GET'])
@jwt_required()
def get_course_statistics(course_id):
    """
    Get statistics for a specific course
    ---
    security:
      - Bearer: []
    parameters:
      - name: course_id
        in: path
        type: integer
        required: true
        description: Course ID
    responses:
      200:
        description: Statistics for the course
        schema:
          type: object
      401:
        description: Unauthorized - Missing or invalid authentication token
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    course_code,
                    course_title,
                    total_events,
                    total_students,
                    present_count,
                    absent_count,
                    late_count,
                    average_attendance_rate
                FROM get_course_statistics(%s);
            """, (course_id,))
            result = dict_from_cursor(cursor)
        return jsonify(result[0] if result else {}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/student/<int:student_id>/attendance', methods=['GET'])
@jwt_required()
def get_student_attendance_summary(student_id):
    """
    Get attendance summary for a specific student
    ---
    parameters:
      - name: student_id
        in: path
        type: integer
        required: true
        description: Student ID
    responses:
      200:
        description: Attendance summary across all courses for the student
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    course_code,
                    course_title,
                    event_count,
                    present_count,
                    absent_count,
                    late_count,
                    no_record_count,
                    attendance_rate
                FROM get_student_attendance_summary(%s)
                ORDER BY course_code;
            """, (student_id,))
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/courses', methods=['GET'])
@jwt_required()
def get_all_courses_statistics():
    """
    Get statistics for all courses
    ---
    security:
      - Bearer: []
    responses:
      200:
        description: List of all courses with their statistics
        schema:
          type: array
          items:
            type: object
      401:
        description: Unauthorized - Missing or invalid authentication token
      500:
        description: Database error
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT
                    statistics.course_code,
                    statistics.course_title,
                    statistics.total_events,
                    statistics.total_students,
                    statistics.present_count,
                    statistics.absent_count,
                    statistics.late_count,
                    statistics.average_attendance_rate
                FROM course c
                CROSS JOIN LATERAL get_course_statistics(c.id) AS statistics
                ORDER BY statistics.course_code;
            """)
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/calendar/events', methods=['GET'])
@jwt_required()
def get_calendar_events():
    """
    Get events for a specific month (calendar view)
    ---
    security:
      - Bearer: []
    parameters:
      - name: month
        in: query
        type: integer
        required: true
        description: Month (1-12)
        example: 2
      - name: year
        in: query
        type: integer
        required: true
        description: Year (e.g., 2026)
        example: 2026
      - name: user_id
        in: query
        type: integer
        required: false
        description: Optional user ID to filter events (organizer or registered student)
        example: 5
    responses:
      200:
        description: Calendar events grouped by day
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            data:
              type: array
              items:
                type: object
                properties:
                  day_of_month:
                    type: integer
                    example: 15
                  event_count:
                    type: integer
                    example: 2
                  events:
                    type: array
                    items:
                      type: object
                      properties:
                        event_id:
                          type: integer
                        event_name:
                          type: string
                        event_type:
                          type: string
                        event_status:
                          type: string
                        start_at:
                          type: string
                          format: date-time
                        stop_at:
                          type: string
                          format: date-time
                        location:
                          type: string
                        course_code:
                          type: string
                        course_title:
                          type: string
                        organizer_name:
                          type: string
                        registration_count:
                          type: integer
                        attendance_stats:
                          type: object
                          properties:
                            present:
                              type: integer
                            absent:
                              type: integer
                            late:
                              type: integer
      400:
        description: Missing required parameters
      401:
        description: Unauthorized
      500:
        description: Server error
    """
    try:
        # Get parameters
        month = request.args.get('month', type=int)
        year = request.args.get('year', type=int)
        user_id = request.args.get('user_id', type=int)
        
        # Validate parameters
        if not month or not year:
            return jsonify({
                'success': False,
                'error': 'Missing required parameters: month and year'
            }), 400
        
        if month < 1 or month > 12:
            return jsonify({
                'success': False,
                'error': 'Invalid month. Must be between 1 and 12'
            }), 400
        
        # Get current user ID from JWT token
        current_user_id = get_jwt_identity()
        
        # If user_id is not provided, use current user
        if user_id is None:
            user_id = current_user_id
        
        # Call the stored procedure
        with Database.get_cursor() as cursor:
            cursor.execute(
                """
                SELECT 
                    day_of_month,
                    event_count,
                    event_id,
                    event_name,
                    event_type,
                    event_status,
                    start_at,
                    stop_at,
                    location,
                    course_code,
                    course_title,
                    organizer_name,
                    registration_count,
                    present_count,
                    absent_count,
                    late_count
                FROM get_events_by_month(%s, %s, %s)
                ORDER BY day_of_month, start_at
                """,
                (month, year, user_id if user_id != current_user_id else None)
            )
            rows = dict_from_cursor(cursor)
        
        # Group events by day for the calendar
        calendar_data = {}
        for row in rows:
            day = row['day_of_month']
            
            if day not in calendar_data:
                calendar_data[day] = {
                    'day_of_month': day,
                    'event_count': row['event_count'],
                    'events': []
                }
            
            # Add event details
            event = {
                'event_id': row['event_id'],
                'event_name': row['event_name'],
                'event_type': row['event_type'],
                'event_status': row['event_status'],
                'start_at': row['start_at'].isoformat() if row['start_at'] else None,
                'stop_at': row['stop_at'].isoformat() if row['stop_at'] else None,
                'location': row['location'],
                'course': {
                    'code': row['course_code'],
                    'title': row['course_title']
                },
                'organizer': row['organizer_name'],
                'registration_count': row['registration_count'],
                'attendance_stats': {
                    'present': row['present_count'],
                    'absent': row['absent_count'],
                    'late': row['late_count']
                }
            }
            calendar_data[day]['events'].append(event)
        
        # Convert to sorted list
        result = sorted(calendar_data.values(), key=lambda x: x['day_of_month'])
        
        return jsonify({
            'success': True,
            'month': month,
            'year': year,
            'data': result
        }), 200
        
    except ValueError:
        return jsonify({
            'success': False,
            'error': 'Invalid parameter types. month and year must be integers'
        }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

