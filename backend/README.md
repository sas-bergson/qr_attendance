# Attendance Management System Flask API

A Flask application that provides RESTful API endpoints to query attendance database statistics using PostgreSQL stored procedures. The API includes JWT authentication, CORS support, and API versioning.

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update with your database and security credentials:

```bash
cp .env.example .env
```

Edit `.env` with your settings:
```
FLASK_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=attendance_db
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET_KEY=your-jwt-secret-key
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:5173
```

### 3. Database Setup

Before running the Flask app, ensure the database is set up:

```bash
cd sql
bash setup.sh
```

This creates the `attendance_db` database with all tables, stored procedures, and test data.

### 4. Run the Application

```bash
python app.py
```

The API will be available at `http://localhost:5000`
Swagger UI documentation: `http://localhost:5000/apidocs`

## Authentication

### Login and Get Tokens

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "student@university.edu", "password": "password123"}'
```

Response:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_id": 1,
  "user_name": "Student Name",
  "role": "Student",
  "expires_in": 3600
}
```

### Use Token in Requests

All protected endpoints require the `Authorization: Bearer <access_token>` header:

```bash
curl -X GET http://localhost:5000/api/v1/departments \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
```

### Refresh Token

```bash
curl -X POST http://localhost:5000/api/auth/refresh \
  -H "Authorization: Bearer <refresh_token>"
```

## API Endpoints

### Authentication (No JWT Required)
- **POST** `/api/auth/login` - Login and get access/refresh tokens
- **POST** `/api/auth/refresh` - Refresh access token (requires refresh token)
- **GET** `/api/auth/me` - Get current user information

### Health Check (No JWT Required)
- **GET** `/api/v1/health` - Check if API and database are healthy

### Departments (JWT Required)
- **GET** `/api/v1/departments` - Get all departments with statistics

### Courses (JWT Required)
- **GET** `/api/v1/courses` - Get statistics for all courses
- **GET** `/api/v1/department/<dept_id>/courses` - Get courses for a department
- **GET** `/api/v1/course/<course_id>/statistics` - Get statistics for a course

### Events (JWT Required)
- **GET** `/api/v1/course/<course_id>/events` - Get events for a course

### Registrations & Attendance (JWT Required)
- **GET** `/api/v1/event/<event_id>/registrations` - Get registrations for an event
- **GET** `/api/v1/student/<student_id>/attendance` - Get attendance summary for a student

## Example Usage

### Check API Health
```bash
curl http://localhost:5000/api/v1/health
```

### Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "student@university.edu", "password": "password123"}'
```

### Get Current User
```bash
curl http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer <access_token>"
```

### Get all departments (requires authentication)
```bash
curl http://localhost:5000/api/v1/departments \
  -H "Authorization: Bearer <access_token>"
```

### Get courses for department 1
```bash
curl http://localhost:5000/api/v1/department/1/courses \
  -H "Authorization: Bearer <access_token>"
```

### Get events for course 1
```bash
curl http://localhost:5000/api/v1/course/1/events \
  -H "Authorization: Bearer <access_token>"
```

## File Structure

```
backend/
├── app.py                 # Flask application factory and main entry point
├── config.py             # Configuration settings (DB, JWT, CORS)
├── database.py           # Database connection and utilities
├── auth.py               # Authentication endpoints (login, refresh, me)
├── routes.py             # API endpoints (v1) and routes
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
├── .env                  # Local environment variables (not in git)
├── README.md             # This file
└── sql/
    ├── models.sql        # Database schema and test data
    ├── setup.sh          # Database setup script
    └── statistics.sql    # Stored procedures for reporting
```

## Features

### ✅ JWT Authentication
- Login with email/password
- Access tokens (1-hour default, configurable)
- Refresh tokens for session renewal
- Current user information endpoint

### ✅ CORS Support
- Configurable CORS origins via environment variable
- Automatic CORS headers on all responses
- Supports multiple frontend domains

### ✅ API Versioning
- All data endpoints use `/api/v1/` prefix
- Auth endpoints use `/api/auth/`
- Health check available without authentication

### ✅ Security
- JWT-based stateless authentication
- Parameterized SQL queries (SQL injection prevention)
- Environment-based secret management
- CORS origin validation

## Notes

- All responses are in JSON format
- Database errors are returned with appropriate HTTP status codes
- The API uses connection pooling via context managers for efficiency
- All data queries use parameterized statements to prevent SQL injection
- Auth endpoints use JWT for token-based authentication
- Access tokens expire after 1 hour (configurable in .env)
