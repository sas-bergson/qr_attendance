from flask import Blueprint, jsonify, request
from database import Database, dict_from_cursor

api = Blueprint('api', __name__, url_prefix='/api')


@api.route('/departments', methods=['GET'])
def get_departments():
    """
    Get all departments with statistics
    ---
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
def get_courses_by_department(dept_id):
    """
    Get all courses for a specific department
    ---
    parameters:
      - name: dept_id
        in: path
        type: integer
        required: true
        description: Department ID
    responses:
      200:
        description: List of courses in the department
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
def get_events_by_course(course_id):
    """
    Get all events for a specific course
    ---
    parameters:
      - name: course_id
        in: path
        type: integer
        required: true
        description: Course ID
    responses:
      200:
        description: List of events in the course
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
                    registrations,
                    present,
                    absent,
                    late
                FROM get_events_by_course(%s)
                ORDER BY start_at;
            """, (course_id,))
            results = dict_from_cursor(cursor)
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@api.route('/event/<int:event_id>/registrations', methods=['GET'])
def get_registrations_by_event(event_id):
    """
    Get all registrations for a specific event
    ---
    parameters:
      - name: event_id
        in: path
        type: integer
        required: true
        description: Event ID
    responses:
      200:
        description: List of registrations for the event
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
def get_course_statistics(course_id):
    """
    Get statistics for a specific course
    ---
    parameters:
      - name: course_id
        in: path
        type: integer
        required: true
        description: Course ID
    responses:
      200:
        description: Statistics for the course
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
def get_all_courses_statistics():
    """
    Get statistics for all courses
    ---
    responses:
      200:
        description: List of all courses with their statistics
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


@api.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    ---
    responses:
      200:
        description: Database is healthy and connected
        schema:
          type: object
          properties:
            status:
              type: string
              example: "healthy"
            database:
              type: string
              example: "connected"
      500:
        description: Database connection failed
    """
    try:
        with Database.get_cursor() as cursor:
            cursor.execute("SELECT 1")
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500
