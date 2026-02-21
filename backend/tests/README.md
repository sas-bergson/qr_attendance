# Testing Guide for Flask Attendance Management System

## Overview

This directory contains comprehensive tests for the Flask Attendance Management System API. Tests are written using **pytest** with **pytest-flask** plugin for Flask-specific testing utilities.

## Test Structure

```
tests/
├── __init__.py              # Package initialization
├── conftest.py              # Pytest fixtures and configuration
├── test_auth_endpoints.py   # Authentication endpoint tests
├── test_api_endpoints.py    # API endpoint tests (protected resources)
└── test_integration.py      # Integration and workflow tests
```

## Running Tests

### Prerequisites

1. **Install dependencies**:
```bash
cd backend
pip install -r requirements.txt
```

2. **Ensure database is running**:
```bash
sudo service postgresql start
```

3. **Ensure test data is loaded** in the database:
The tests use real user credentials from `models.sql`:
- Student: `chidubem.okoye@student.university.edu` / `hashed_pass_se_001`
- Lecturer: `emily.johnson@university.edu` / `hashed_password_1`
- Admin: `admin@university.edu` / `hashed_password_admin`

### Run All Tests

```bash
pytest
```

### Run Specific Test File

```bash
# Test authentication endpoints
pytest tests/test_auth_endpoints.py -v

# Test API endpoints
pytest tests/test_api_endpoints.py -v

# Test integration workflows
pytest tests/test_integration.py -v
```

### Run Specific Test Class

```bash
pytest tests/test_auth_endpoints.py::TestAuthLogin -v
```

### Run Specific Test

```bash
pytest tests/test_auth_endpoints.py::TestAuthLogin::test_login_successful_student -v
```

### Run with Coverage Report

```bash
pytest --cov=app --cov=routes --cov=auth --cov-report=html
```

This generates an HTML coverage report in `htmlcov/index.html`

### Run with Different Verbosity Levels

```bash
# Verbose output
pytest -v

# Very verbose (show each test step)
pytest -vv

# Quiet mode
pytest -q
```

## Test Categories

### 1. Authentication Tests (`test_auth_endpoints.py`)

**TestAuthLogin**: Tests for POST `/api/auth/login`
- ✓ Successful login with different user roles (student, lecturer, admin)
- ✓ Invalid credentials handling
- ✓ Missing required fields validation
- ✓ JWT token structure validation

**TestAuthRefresh**: Tests for POST `/api/auth/refresh`
- ✓ Successful token refresh
- ✓ Invalid refresh token handling
- ✓ Missing authorization header

**TestAuthMe**: Tests for GET `/api/auth/me`
- ✓ Getting current user info for different roles
- ✓ Authorization requirement validation
- ✓ Invalid token handling

### 2. API Endpoint Tests (`test_api_endpoints.py`)

**TestHealthCheck**: Tests for GET `/api/v1/health` (no auth required)
- ✓ Health check success
- ✓ Database connectivity verification

**TestDepartmentsEndpoint**: Tests for GET `/api/v1/departments` (requires auth)
- ✓ Getting all departments
- ✓ Response structure validation
- ✓ Authentication requirements
- ✓ Multi-role access control

**TestCoursesEndpoint**: Tests for GET `/api/v1/department/<dept_id>/courses`
- ✓ Getting courses by department
- ✓ Specific course codes verification
- ✓ Response structure validation

**TestEventsEndpoint**: Tests for GET `/api/v1/course/<course_id>/events`
- ✓ Getting events by course
- ✓ Event status verification

**TestRegistrationsEndpoint**: Tests for GET `/api/v1/event/<event_id>/registrations`
- ✓ Getting registrations by event
- ✓ Response structure validation

**TestRootEndpoint**: Tests for GET `/`
- ✓ API documentation availability
- ✓ Endpoint information

**TestErrorHandling**: General error handling
- ✓ 404 Not Found
- ✓ 405 Method Not Allowed
- ✓ 401 Unauthorized

### 3. Integration Tests (`test_integration.py`)

**TestFullAuthenticationFlow**: Complete authentication workflows
- ✓ Login → Use token → Access resource
- ✓ Login → Refresh → Use new token → Access resource

**TestMultipleUserRoles**: Role-based access control
- ✓ Student role access
- ✓ Lecturer role access
- ✓ Admin role access

**TestDataConsistency**: Data consistency verification
- ✓ Department count consistency
- ✓ Course event data
- ✓ Event data structure

**TestContentTypes**: HTTP content type validation
- ✓ JSON responses
- ✓ Correct content-type headers

## Test Fixtures

Available fixtures in `conftest.py`:

### Application Fixtures
- **`app`**: Flask application instance
- **`client`**: Flask test client
- **`runner`**: Flask CLI runner
- **`app_context`**: Application context for database operations

### Authentication Fixtures
- **`auth_headers`**: Student authentication headers
- **`lecturer_auth_headers`**: Lecturer authentication headers
- **`admin_auth_headers`**: Admin authentication headers

### Test Data
- **`TEST_USERS`**: Dictionary with test user credentials

## Test User Credentials

### Student
```json
{
  "email": "chidubem.okoye@student.university.edu",
  "password": "hashed_pass_se_001",
  "name": "Chidubem Okoye",
  "role": "Student"
}
```

### Lecturer
```json
{
  "email": "emily.johnson@university.edu",
  "password": "hashed_password_1",
  "name": "Dr. Emily Johnson",
  "role": "Lecturer"
}
```

### Admin
```json
{
  "email": "admin@university.edu",
  "password": "hashed_password_admin",
  "name": "Admin User",
  "role": "Administrator"
}
```

## Best Practices Implemented

1. **Fixture Scope**: Fixtures use appropriate scope (function-level for client isolation)
2. **Assertion Messages**: Clear, descriptive assertions with context
3. **Test Independence**: Each test is independent and can run in any order
4. **Response Validation**: Comprehensive validation of:
   - Status codes
   - Response structure
   - Data types
   - Content
5. **Error Cases**: Thorough coverage of:
   - Missing fields
   - Invalid credentials
   - Authentication failures
   - Invalid tokens
6. **Role-Based Testing**: Tests verify access control for different user roles
7. **Data Validation**: Tests verify response data matches expected values

## Continuous Integration

To add these tests to CI/CD pipeline, use:

```bash
pytest --cov=app --cov=routes --cov=auth --cov-report=xml
```

The `--cov-report=xml` generates a coverage report in JUnit XML format suitable for CI systems.

## Troubleshooting

### Database Connection Issues
```
If tests fail with database connection errors:
1. Verify PostgreSQL is running: sudo service postgresql status
2. Check database exists: psql -l | grep attendance_db
3. Verify test user credentials are loaded in database
```

### JWT Token Errors
```
If tests fail with "Invalid token" errors:
1. Check JWT_SECRET_KEY in config.py matches Flask app
2. Verify token expiration isn't too short
3. Check Authorization header format: "Bearer <token>"
```

### Port Already in Use
```
If Flask test client fails to start:
1. Kill any existing Flask processes: killall python
2. Check for other services on port 5000: lsof -i :5000
```

## Performance

Test execution time (approximate):
- Full test suite: ~5-10 seconds
- Single test: <100ms
- With coverage: ~15-20 seconds

## Future Enhancements

Planned test improvements:
- [ ] Database transaction rollback for test isolation
- [ ] Load testing with pytest-benchmark
- [ ] API contract testing
- [ ] Mock external services
- [ ] Performance profiling
