#!/bin/bash

# PostgreSQL 12 Compatible Database Setup Script
# This script handles database creation for PostgreSQL 12

echo "=========================================="
echo "PostgreSQL 12 Database Setup"
echo "=========================================="

# Drop existing database if needed
echo "Cleaning up existing database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS attendance_db;" 2>/dev/null
echo "Cleanup complete."

# Create the database
echo "Creating database 'attendance_db'..."
sudo -u postgres psql -c "CREATE DATABASE attendance_db WITH ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE = template0;"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create database"
    exit 1
fi

echo "Database created successfully!"

# Run the SQL script
echo "Running SQL schema and test data..."
sudo -u postgres psql -d attendance_db -f ./models.sql

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to load SQL schema"
    exit 1
fi

echo ""
echo "=========================================="
echo "Verifying Database Setup"
echo "=========================================="
echo ""

# Run verification queries
sudo -u postgres psql -d attendance_db << 'VERIFY_EOF'
\echo '╔════════════════════════════════════════════════════════════╗'
\echo '║      UNIVERSITY ATTENDANCE SYSTEM - DATABASE SETUP         ║'
\echo '║                    VERIFICATION REPORT                     ║'
\echo '╚════════════════════════════════════════════════════════════╝'
\echo ''
\echo 'DATABASE OBJECTS:'
\echo '─────────────────'
SELECT object_type, count FROM (
  SELECT 'ENUM Types' as object_type, COUNT(*) as count FROM pg_type WHERE typtype = 'e'
  UNION ALL
  SELECT 'Tables', COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'
  UNION ALL
  SELECT 'Indexes', COUNT(*) FROM pg_indexes WHERE schemaname = 'public'
) AS db_objects
ORDER BY object_type;

\echo ''
\echo 'TEST DATA:'
\echo '──────────'
SELECT description, count FROM (
  SELECT 'Students (Role=Student)' as description, COUNT(*) as count FROM "user" WHERE role_id=1
  UNION ALL
  SELECT 'Lecturers (Role=Lecturer)', COUNT(*) FROM "user" WHERE role_id=2
  UNION ALL
  SELECT 'Admin (Role=Administrator)', COUNT(*) FROM "user" WHERE role_id=3
  UNION ALL
  SELECT 'Departments', COUNT(*) FROM department
  UNION ALL
  SELECT 'Courses', COUNT(*) FROM course
  UNION ALL
  SELECT 'Events (Classes)', COUNT(*) FROM event
  UNION ALL
  SELECT 'Registrations', COUNT(*) FROM registration
  UNION ALL
  SELECT 'QR Codes', COUNT(*) FROM qr_code
  UNION ALL
  SELECT 'Presence Records', COUNT(*) FROM presence
) AS test_data
ORDER BY description;

\echo ''
\echo 'DEPARTMENT BREAKDOWN:'
\echo '────────────────────'
SELECT d.name as department, COUNT(DISTINCT e.id) as events, COUNT(DISTINCT r.user_id) as students
FROM department d
LEFT JOIN course c ON c.department_id = d.id
LEFT JOIN event e ON e.course_id = c.id
LEFT JOIN registration r ON r.event_id = e.id AND r.status = 'completed'
GROUP BY d.id, d.name
ORDER BY d.id;

\echo ''
\echo 'COURSES BREAKDOWN:'
\echo '──────────────────'
SELECT d.name as department, c.code as course, COUNT(DISTINCT e.id) as events, COUNT(DISTINCT r.user_id) as students
FROM course c
LEFT JOIN department d ON d.id = c.department_id
LEFT JOIN event e ON e.course_id = c.id
LEFT JOIN registration r ON r.event_id = e.id AND r.status = 'completed'
GROUP BY d.id, d.name, c.id, c.code
ORDER BY d.id, c.id;

\echo ''
\echo '✓ Database fully operational and ready for Flask integration!'
\echo ''
VERIFY_EOF

echo ""
echo "=========================================="
echo "Connection Information"
echo "=========================================="
echo ""
echo "Database: attendance_db"
echo "Host: localhost"
echo "Port: 5432"
echo ""
echo "Verify installation:"
echo "  sudo -u postgres psql -d attendance_db -c \"\\dt\""
echo ""
echo "Connect to database:"
echo "  sudo -u postgres psql -d attendance_db"
echo ""
