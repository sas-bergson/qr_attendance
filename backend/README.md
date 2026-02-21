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

#### POST `/api/auth/login`
Login and get access/refresh tokens

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "student@university.edu",
  "password": "password123"
}
```

**Response (200 OK):**
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

#### POST `/api/auth/refresh`
Refresh access token using refresh token

**Request Headers:**
```
Authorization: Bearer <refresh_token>
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "expires_in": 3600
}
```

#### GET `/api/auth/me`
Get current user information

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "user_id": 1,
  "email": "student@university.edu",
  "name": "Student Name",
  "role": "Student"
}
```

---

### Health Check (No JWT Required)

#### GET `/api/v1/health`
Check if API and database are healthy

**Response (200 OK):**
```json
{
  "status": "healthy",
  "database": "connected"
}
```

---

### Departments (JWT Required)

#### GET `/api/v1/departments`
Get all departments with statistics

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Computer Science",
    "student_count": 150,
    "course_count": 8
  }
]
```

---

### Courses (JWT Required)

#### GET `/api/v1/courses`
Get statistics for all courses

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Data Structures",
    "code": "CS101",
    "department_id": 1,
    "registration_count": 45,
    "present_count": 40,
    "absent_count": 5,
    "late_count": 2
  }
]
```

#### GET `/api/v1/department/<dept_id>/courses`
Get courses for a department

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
- `dept_id` (integer, required) - Department ID

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Data Structures",
    "code": "CS101",
    "department_id": 1
  }
]
```

#### GET `/api/v1/course/<course_id>/statistics`
Get statistics for a course

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
- `course_id` (integer, required) - Course ID

**Response (200 OK):**
```json
{
  "course_id": 1,
  "course_name": "Data Structures",
  "registration_count": 45,
  "present_count": 40,
  "absent_count": 5,
  "late_count": 2
}
```

---

### Events (JWT Required)

#### GET `/api/v1/course/<course_id>/events`
Get events for a course

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
- `course_id` (integer, required) - Course ID

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "course_id": 1,
    "event_date": "2024-02-21",
    "event_type": "Lecture",
    "registration_count": 45,
    "present_count": 42,
    "absent_count": 2,
    "late_count": 1
  }
]
```

---

### Registrations & Attendance (JWT Required)

#### GET `/api/v1/event/<event_id>/registrations`
Get registrations for an event

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
- `event_id` (integer, required) - Event ID

**Response (200 OK):**
```json
[
  {
    "student_id": 1,
    "student_name": "John Doe",
    "email": "john@university.edu",
    "status": "present|absent|late"
  }
]
```

#### GET `/api/v1/student/<student_id>/attendance`
Get attendance summary for a student

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**URL Parameters:**
- `student_id` (integer, required) - Student ID

**Response (200 OK):**
```json
{
  "student_id": 1,
  "student_name": "John Doe",
  "total_events": 30,
  "present": 28,
  "absent": 1,
  "late": 1
}
```

## Example Usage

### 1. Check API Health (No Auth Required)
```bash
curl http://localhost:5000/api/v1/health
```

### 2. Login and Get Tokens
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "chidubem.okoye@student.university.edu",
    "password": "password123"
  }'
```

Save the `access_token` from the response.

### 3. Get Current User (Using Access Token)
```bash
curl http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer <access_token>"
```

### 4. Get All Departments (Requires Authentication)
```bash
curl http://localhost:5000/api/v1/departments \
  -H "Authorization: Bearer <access_token>"
```

### 5. Get Courses for Department 1
```bash
curl http://localhost:5000/api/v1/department/1/courses \
  -H "Authorization: Bearer <access_token>"
```

### 6. Get Statistics for Course 1
```bash
curl http://localhost:5000/api/v1/course/1/statistics \
  -H "Authorization: Bearer <access_token>"
```

### 7. Get Events for Course 1
```bash
curl http://localhost:5000/api/v1/course/1/events \
  -H "Authorization: Bearer <access_token>"
```

### 8. Get Registrations for Event 1
```bash
curl http://localhost:5000/api/v1/event/1/registrations \
  -H "Authorization: Bearer <access_token>"
```

### 9. Get Attendance Summary for Student 1
```bash
curl http://localhost:5000/api/v1/student/1/attendance \
  -H "Authorization: Bearer <access_token>"
```

### 10. Refresh Expired Access Token
```bash
curl -X POST http://localhost:5000/api/auth/refresh \
  -H "Authorization: Bearer <refresh_token>"
```

## Authentication Flow Diagram

```
1. Login Request (POST /api/auth/login)
   ↓
2. Receive access_token & refresh_token
   ↓
3. Use access_token in Authorization header for protected endpoints
   ↓
4. Token Expires (1 hour default)
   ↓
5. Use refresh_token to get new access_token (POST /api/auth/refresh)
   ↓
6. Continue using new access_token
```

## Error Responses

### Unauthorized (401)
Missing or invalid authentication token:
```json
{
  "error": "Missing Authorization Header"
}
```

### Invalid Credentials (401)
```json
{
  "error": "Invalid email or password"
}
```

### Not Found (404)
```json
{
  "error": "Resource not found"
}
```

### Server Error (500)
```json
{
  "error": "Internal server error"
}
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
