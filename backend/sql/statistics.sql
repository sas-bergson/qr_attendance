-- ============================================================================
-- UNIVERSITY ATTENDANCE SYSTEM - STATISTICS AND REPORTING
-- ============================================================================
-- This script demonstrates creation and use of stored procedures
-- for data analysis and reporting of attendance system data
-- ============================================================================

-- ============================================================================
-- STORED PROCEDURE 1: Get Courses by Department
-- ============================================================================
-- Purpose: Display all courses within a specific department
-- Parameters: department_id (BIGINT)
-- Returns: Course details including course code, name, and event count

DROP FUNCTION IF EXISTS get_courses_by_department (BIGINT);

CREATE OR REPLACE FUNCTION get_courses_by_department(p_department_id BIGINT)
RETURNS TABLE (
    course_id BIGINT,
    department_name VARCHAR,
    course_code VARCHAR,
    course_title VARCHAR,
    event_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        d.name,
        c.code,
        c.title,
        COUNT(DISTINCT e.id) as event_count
    FROM course c
    LEFT JOIN department d ON d.id = c.department_id
    LEFT JOIN event e ON e.course_id = c.id
    WHERE c.department_id = p_department_id
    GROUP BY c.id, d.id, d.name, c.code, c.title
    ORDER BY c.code;
END;
$$ LANGUAGE plpgsql;

\echo ''
\echo '✓ Stored Procedure 1: get_courses_by_department() created successfully'

-- ============================================================================
-- STORED PROCEDURE 2: Get Events by Course
-- ============================================================================
-- Purpose: Display all events (classes) for a specific course
-- Parameters: course_id (BIGINT)
-- Returns: Event details including event type, status, and student count

DROP FUNCTION IF EXISTS get_events_by_course (BIGINT);

CREATE OR REPLACE FUNCTION get_events_by_course(p_course_id BIGINT)
RETURNS TABLE (
    event_id BIGINT,
    course_code VARCHAR,
    course_title VARCHAR,
    event_name VARCHAR,
    event_type TEXT,
    event_status TEXT,
    start_at TIMESTAMP WITH TIME ZONE,
    organizer_name VARCHAR,
    registration_count BIGINT,
    present_count BIGINT,
    absent_count BIGINT,
    late_count BIGINT
) AS $$
    SELECT
        e.id::BIGINT,
        c.code,
        c.title,
        e.name,
        e.type::text,
        e.status::text,
        e.start_at,
        u.name,
        COUNT(DISTINCT CASE WHEN r.status = 'completed' THEN r.id END)::BIGINT as registration_count,
        COUNT(DISTINCT CASE WHEN p.status = 'present' THEN p.id END)::BIGINT as present_count,
        COUNT(DISTINCT CASE WHEN p.status = 'absent' THEN p.id END)::BIGINT as absent_count,
        COUNT(DISTINCT CASE WHEN p.status = 'late' THEN p.id END)::BIGINT as late_count
    FROM event e
    LEFT JOIN course c ON c.id = e.course_id
    LEFT JOIN "user" u ON u.id = e.organizer_id
    LEFT JOIN registration r ON r.event_id = e.id
    LEFT JOIN presence p ON p.event_id = e.id
    WHERE e.course_id = p_course_id
    GROUP BY e.id, c.code, c.title, e.name, e.type, e.status, e.start_at, u.name
    ORDER BY e.start_at;
$$ LANGUAGE SQL;

\echo '✓ Stored Procedure 2: get_events_by_course() created successfully'

-- ============================================================================
-- STORED PROCEDURE 3: Get Registrations by Event
-- ============================================================================
-- Purpose: Display all student registrations for a specific event
-- Parameters: event_id (BIGINT)
-- Returns: Student details with their attendance status

DROP FUNCTION IF EXISTS get_registrations_by_event (BIGINT);

CREATE OR REPLACE FUNCTION get_registrations_by_event(p_event_id BIGINT)
RETURNS TABLE (
    registration_id BIGINT,
    student_id BIGINT,
    student_name VARCHAR,
    student_email VARCHAR,
    department_name VARCHAR,
    registration_status VARCHAR,
    completed_at TIMESTAMP WITH TIME ZONE,
    attendance_status VARCHAR,
    scanned_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        u.id,
        u.name,
        u.email,
        d.name,
        r.status::text::VARCHAR,
        r.completed_at,
        COALESCE(p.status::text::VARCHAR, 'not-marked'),
        p.scanned_at
    FROM registration r
    LEFT JOIN "user" u ON u.id = r.user_id
    LEFT JOIN department d ON d.id = u.department_id
    LEFT JOIN presence p ON p.user_id = u.id AND p.event_id = r.event_id
    WHERE r.event_id = p_event_id
    ORDER BY u.name;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Stored Procedure 3: get_registrations_by_event() created successfully'

-- ============================================================================
-- STORED PROCEDURE 4: Get Department Statistics
-- ============================================================================
-- Purpose: Display comprehensive statistics for a department
-- Parameters: department_id (BIGINT)
-- Returns: Department statistics including courses, events, and students

DROP FUNCTION IF EXISTS get_department_statistics (BIGINT);

CREATE OR REPLACE FUNCTION get_department_statistics(p_department_id BIGINT)
RETURNS TABLE (
    department_name VARCHAR,
    total_courses BIGINT,
    total_events BIGINT,
    total_students BIGINT,
    total_registrations BIGINT,
    attendance_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.name,
        COUNT(DISTINCT c.id) as total_courses,
        COUNT(DISTINCT e.id) as total_events,
        COUNT(DISTINCT u.id) as total_students,
        COUNT(DISTINCT r.id) as total_registrations,
        ROUND(
            100.0 * COUNT(CASE WHEN p.status IN ('present', 'late') THEN 1 END) /
            NULLIF(COUNT(p.id), 0),
            2
        ) as attendance_rate
    FROM department d
    LEFT JOIN course c ON c.department_id = d.id
    LEFT JOIN event e ON e.course_id = c.id
    LEFT JOIN registration r ON r.event_id = e.id AND r.status = 'completed'
    LEFT JOIN "user" u ON u.id = r.user_id AND u.department_id = d.id
    LEFT JOIN presence p ON p.event_id = e.id AND p.user_id = u.id
    WHERE d.id = p_department_id
    GROUP BY d.id, d.name;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Stored Procedure 4: get_department_statistics() created successfully'

-- ============================================================================
-- STORED PROCEDURE 5: Get Course Statistics
-- ============================================================================
-- Purpose: Display comprehensive statistics for a course
-- Parameters: course_id (BIGINT)
-- Returns: Course statistics including events, students, and attendance

DROP FUNCTION IF EXISTS get_course_statistics (BIGINT);

CREATE OR REPLACE FUNCTION get_course_statistics(p_course_id BIGINT)
RETURNS TABLE (
    department_name VARCHAR,
    course_code VARCHAR,
    course_title VARCHAR,
    total_events BIGINT,
    total_students BIGINT,
    total_registrations BIGINT,
    present_count BIGINT,
    absent_count BIGINT,
    late_count BIGINT,
    average_attendance_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.name,
        c.code,
        c.title,
        COUNT(DISTINCT e.id) as total_events,
        COUNT(DISTINCT r.user_id) as total_students,
        COUNT(DISTINCT r.id) as total_registrations,
        COUNT(CASE WHEN p.status = 'present' THEN 1 END) as present_count,
        COUNT(CASE WHEN p.status = 'absent' THEN 1 END) as absent_count,
        COUNT(CASE WHEN p.status = 'late' THEN 1 END) as late_count,
        ROUND(
            100.0 * COUNT(CASE WHEN p.status IN ('present', 'late') THEN 1 END) /
            NULLIF(COUNT(p.id), 0),
            2
        ) as average_attendance_rate
    FROM course c
    LEFT JOIN department d ON d.id = c.department_id
    LEFT JOIN event e ON e.course_id = c.id
    LEFT JOIN registration r ON r.event_id = e.id AND r.status = 'completed'
    LEFT JOIN presence p ON p.event_id = e.id AND p.user_id = r.user_id
    WHERE c.id = p_course_id
    GROUP BY c.id, d.id, d.name, c.code, c.title;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Stored Procedure 5: get_course_statistics() created successfully'

-- ============================================================================
-- STORED PROCEDURE 6: Get Student Attendance Summary
-- ============================================================================
-- Purpose: Display attendance summary for a specific student
-- Parameters: user_id (BIGINT)
-- Returns: Student's attendance records across all courses

DROP FUNCTION IF EXISTS get_student_attendance_summary (BIGINT);

CREATE OR REPLACE FUNCTION get_student_attendance_summary(p_user_id BIGINT)
RETURNS TABLE (
    course_code VARCHAR,
    course_title VARCHAR,
    event_count BIGINT,
    present_count BIGINT,
    absent_count BIGINT,
    late_count BIGINT,
    no_record_count BIGINT,
    attendance_rate NUMERIC
) AS $$
    SELECT
        c.code,
        c.title,
        COUNT(DISTINCT e.id)::BIGINT as event_count,
        COUNT(CASE WHEN p.status = 'present' THEN 1 END)::BIGINT as present_count,
        COUNT(CASE WHEN p.status = 'absent' THEN 1 END)::BIGINT as absent_count,
        COUNT(CASE WHEN p.status = 'late' THEN 1 END)::BIGINT as late_count,
        COUNT(CASE WHEN p.id IS NULL THEN 1 END)::BIGINT as no_record_count,
        ROUND(
            100.0 * COUNT(CASE WHEN p.status IN ('present', 'late') THEN 1 END) /
            NULLIF(COUNT(DISTINCT e.id), 0),
            2
        ) as attendance_rate
    FROM course c
    INNER JOIN event e ON e.course_id = c.id
    INNER JOIN registration r ON r.event_id = e.id AND r.user_id = p_user_id AND r.status = 'completed'
    LEFT JOIN presence p ON p.event_id = e.id AND p.user_id = p_user_id
    GROUP BY c.id, c.code, c.title
    ORDER BY c.code;
$$ LANGUAGE SQL;

\echo '✓ Stored Procedure 6: get_student_attendance_summary() created successfully'

-- ============================================================================
-- DEMONSTRATION: Using the Stored Procedures
-- ============================================================================


\pset pager off

\echo ''
\echo '╔═══════════════════════════════════════════════════════════════════╗'
\echo '║            STORED PROCEDURES - DEMONSTRATION OUTPUT               ║'
\echo '╚═══════════════════════════════════════════════════════════════════╝'

-- Demonstration 1: Get Courses by Department
\echo ''
\echo '>>> DEMONSTRATION 1: COURSES BY DEPARTMENT'
\echo '─────────────────────────────────────────'
\echo 'All Departments with Their Courses'
\echo ''

SELECT d.name as department, c.course_code, c.course_title, c.event_count
FROM
    department d
    CROSS JOIN LATERAL get_courses_by_department (d.id) c
WHERE
    d.deleted_at IS NULL
ORDER BY d.id, c.course_code;

-- Demonstration 2: Get Events by Course
\echo ''
\echo '>>> DEMONSTRATION 2: EVENTS BY COURSE'
\echo '────────────────────────────────────'
\echo 'All Courses with Their Events'
\echo ''

SELECT
    d.name as department,
    c.code as course_code,
    c.title as course_title,
    e.event_name,
    e.event_type,
    e.start_at,
    e.organizer_name,
    e.registration_count,
    e.present_count,
    e.absent_count,
    e.late_count
FROM
    department d
    INNER JOIN course c ON c.department_id = d.id
    CROSS JOIN LATERAL get_events_by_course (c.id) e
WHERE
    d.deleted_at IS NULL
    AND c.deleted_at IS NULL
ORDER BY d.id, c.code, e.start_at;

-- Demonstration 3: Get Registrations by Event
\set demo_event_id 1
\echo ''
\echo '>>> DEMONSTRATION 3: REGISTRATIONS BY EVENT'
\echo '───────────────────────────────────────────'

SELECT e.name || ' (Event ID: ' || e.id || ')' AS event_info
FROM event e
WHERE e.id = :demo_event_id;

\echo ''

SELECT
    student_name,
    student_email,
    registration_status,
    attendance_status,
    scanned_at
FROM get_registrations_by_event (:demo_event_id)
ORDER BY student_name;

-- Demonstration 4: Department Statistics
\echo ''
\echo '>>> DEMONSTRATION 4: DEPARTMENT STATISTICS'
\echo '─────────────────────────────────────────'
\echo 'All Departments Overview'
\echo ''

SELECT statistics.department_name, statistics.total_courses, statistics.total_events, statistics.total_students, statistics.total_registrations, statistics.attendance_rate
FROM
    department d
    CROSS JOIN LATERAL get_department_statistics (d.id) AS statistics
ORDER BY statistics.department_name;

-- Demonstration 5: Course Statistics
\echo ''
\echo '>>> DEMONSTRATION 5: COURSE STATISTICS'
\echo '──────────────────────────────────────'
\echo 'All Courses Overview'
\echo ''

SELECT statistics.course_code, statistics.course_title, statistics.total_events, statistics.total_students, statistics.present_count, statistics.absent_count, statistics.late_count, statistics.average_attendance_rate
FROM
    course c
    CROSS JOIN LATERAL get_course_statistics (c.id) AS statistics
ORDER BY statistics.course_code;

-- Demonstration 6: Student Attendance Summary
\set demo_student_id 5
\echo ''
\echo '>>> DEMONSTRATION 6: STUDENT ATTENDANCE SUMMARY'
\echo '───────────────────────────────────────────────'

SELECT 'Student ID: ' || u.id || ', Name: ' || u.name || ', Department: ' || d.name AS student_info
FROM "user" u
JOIN department d ON u.department_id = d.id
WHERE u.id = :demo_student_id;

\echo ''

SELECT
    course_code,
    course_title,
    event_count,
    present_count,
    absent_count,
    late_count,
    no_record_count,
    attendance_rate
FROM
    get_student_attendance_summary (:demo_student_id)
ORDER BY course_code;

-- ============================================================================
-- SUMMARY
-- ============================================================================

\echo ''
\echo '╔═══════════════════════════════════════════════════════════════════╗'
\echo '║              6 STORED PROCEDURES CREATED SUCCESSFULLY             ║'
\echo '╠═══════════════════════════════════════════════════════════════════╣'
\echo '║                                                                   ║'
\echo '║  1. get_courses_by_department()     - Courses per department      ║'
\echo '║  2. get_events_by_course()          - Events per course           ║'
\echo '║  3. get_registrations_by_event()    - Registrations per event     ║'
\echo '║  4. get_department_statistics()     - Department analytics        ║'
\echo '║  5. get_course_statistics()         - Course analytics            ║'
\echo '║  6. get_student_attendance_summary()- Student attendance tracking ║'
\echo '║                                                                   ║'
\echo '║  All procedures use RETURNS TABLE syntax for flexible data        ║'
\echo '║  retrieval and can be used in complex queries with JOINs         ║'
\echo '║                                                                   ║'
\echo '╚═══════════════════════════════════════════════════════════════════╝'
\echo ''