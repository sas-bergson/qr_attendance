# Attendance Management System Flask API

A Flask application that provides RESTful API endpoints to query attendance database statistics using PostgreSQL stored procedures.

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update with your database credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=attendance_db
DB_USER=postgres
DB_PASSWORD=your_password
```

### 3. Run the Application

```bash
python app.py
```

The API will be available at `http://localhost:5000`

## API Endpoints

### Health Check
- **GET** `/api/health` - Check if database connection is working

### Departments
- **GET** `/api/departments` - Get all departments with statistics (courses, events, students, attendance rate)

### Courses
- **GET** `/api/courses` - Get statistics for all courses
- **GET** `/api/department/<dept_id>/courses` - Get all courses for a specific department
- **GET** `/api/course/<course_id>/statistics` - Get detailed statistics for a specific course

### Events
- **GET** `/api/course/<course_id>/events` - Get all events for a specific course

### Registrations & Attendance
- **GET** `/api/event/<event_id>/registrations` - Get all registrations for a specific event
- **GET** `/api/student/<student_id>/attendance` - Get attendance summary for a specific student

## Example Usage

### Get all departments
```bash
curl http://localhost:5000/api/departments
```

### Get courses for department 1
```bash
curl http://localhost:5000/api/department/1/courses
```

### Get events for course 1
```bash
curl http://localhost:5000/api/course/1/events
```

### Get registrations for event 1
```bash
curl http://localhost:5000/api/event/1/registrations
```

### Get student attendance summary for student 5
```bash
curl http://localhost:5000/api/student/5/attendance
```

## File Structure

```
backend/
├── app.py                 # Flask application factory and main entry point
├── config.py             # Configuration settings
├── database.py           # Database connection and utilities
├── routes.py             # API endpoints and routes
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
├── .env                  # Local environment variables (not in git)
└── sql/
    ├── models.sql        # Database schema and test data
    ├── setup.sh          # Database setup script
    └── statistics.sql    # Stored procedures for reporting
```

## Database Setup

Before running the Flask app, ensure the database is set up:

```bash
cd sql
bash setup.sh
```

This creates the `attendance_db` database with all tables, stored procedures, and test data.

## Notes

- All responses are in JSON format
- Database errors are returned with appropriate HTTP status codes
- The API uses connection pooling via context managers for efficiency
- All queries use parameterized statements to prevent SQL injection
