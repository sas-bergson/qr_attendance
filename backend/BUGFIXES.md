# Bug Fixes & Test Corrections Log

## Overview
This document tracks all bug fixes and test corrections applied to the Flask Attendance Management System. Last updated: February 22, 2026.

---

## Fix #5: Incorrect HTTP Status Code Expectations in Tests

**Issue ID**: BUGFIX-005  
**Date Fixed**: February 21, 2026  
**Severity**: Low  
**Status**: ✅ RESOLVED

### Description
Two test cases expected HTTP 422 for malformed Authorization headers, but Flask-JWT-Extended correctly returns 401 (Unauthorized).

### Root Cause
Test expectations were based on incorrect assumptions about error handling. HTTP 401 Unauthorized is the correct response for:
- Missing authentication credentials
- Invalid tokens
- Malformed authentication headers

HTTP 422 (Unprocessable Entity) is for:
- Valid syntax but semantic errors
- Failed validation constraints

### Impact
- **Test Failures**: 2 tests failed
  - `test_refresh_with_malformed_header`
  - `test_get_current_user_malformed_header`

### Solution
Updated test expectations to correct HTTP status code:

**File**: `tests/test_auth_endpoints.py`

```python
# Before:
def test_refresh_with_malformed_header(self, client):
    """Test refresh with malformed Authorization header"""
    response = client.post(
        '/api/auth/refresh',
        headers={'Authorization': 'InvalidHeader token'}
    )
    assert response.status_code == 422  # ❌ Wrong

# After:
def test_refresh_with_malformed_header(self, client):
    """Test refresh with malformed Authorization header"""
    response = client.post(
        '/api/auth/refresh',
        headers={'Authorization': 'InvalidHeader token'}
    )
    # Malformed auth header should return 401 (Unauthorized), not 422
    assert response.status_code == 401  # ✅ Correct
```

Applied same fix to: `test_get_current_user_malformed_header`

### HTTP Status Codes Reference
| Code | Meaning              | Use Case                                   |
| ---- | -------------------- | ------------------------------------------ |
| 400  | Bad Request          | Malformed JSON, missing required fields    |
| 401  | Unauthorized         | Invalid/missing credentials, invalid token |
| 422  | Unprocessable Entity | Valid syntax but failed validation         |
| 500  | Server Error         | Unexpected exception                       |

### Test Cases Affected
- ✅ `test_refresh_with_malformed_header` (corrected expectation)
- ✅ `test_get_current_user_malformed_header` (corrected expectation)

---

## Fix #4: SQL Column Name Mismatch in Events Endpoint

**Issue ID**: BUGFIX-004  
**Date Fixed**: February 21, 2026  
**Severity**: High  
**Status**: ✅ RESOLVED

### Description
The `/api/v1/course/<id>/events` endpoint selected wrong column names, causing SQL errors when querying the `get_events_by_course()` stored procedure.

### Root Cause
The SELECT statement in routes.py didn't match the actual column names returned by the stored function:

**Stored Function Returns**:
- `registration_count`
- `present_count`
- `absent_count`
- `late_count`

**Code Was Selecting**:
- `registrations` ❌
- `present` ❌
- `absent` ❌
- `late` ❌

### Error Message
```
column "registrations" does not exist
LINE 11:                     registrations,
                             ^\
```

### Impact
- **Test Failures**: 
  - `test_get_events_by_course_success` (500 error)
  - `test_get_events_contains_different_statuses` (500 error)
  - `test_event_data_structure` (integration test)
- **Business Impact**: Events endpoint completely non-functional

### Solution
Updated SELECT clause to match stored function output columns:

**File**: `routes.py` (Lines 154-167)

```python
# Before:
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
        registrations,      # ❌ Wrong
        present,            # ❌ Wrong
        absent,             # ❌ Wrong
        late                # ❌ Wrong
    FROM get_events_by_course(%s)
""")

# After:
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
        registration_count, # ✅ Correct
        present_count,      # ✅ Correct
        absent_count,       # ✅ Correct
        late_count          # ✅ Correct
    FROM get_events_by_course(%s)
""")
```

### SQL Stored Function Reference
**File**: `sql/statistics.sql` (Lines 47-85)

The `get_events_by_course()` function definition documents the exact return columns.

### Test Cases Affected
- ✅ `test_get_events_by_course_success` (was 500, now 200)
- ✅ `test_get_events_contains_different_statuses` (was 500, now 200)
- ✅ `test_event_data_structure` (integration test)

### Verification
```bash
curl -X GET http://localhost:5000/api/v1/course/1/events \
  -H "Authorization: Bearer <valid_token>"
# Result: 200 OK with proper event data ✅
```

---

## Fix #3: Unhandled Exception on Missing JSON Body

**Issue ID**: BUGFIX-003  
**Date Fixed**: February 21, 2026  
**Severity**: High  
**Status**: ✅ RESOLVED

### Description
The login endpoint threw an unhandled exception (500 error) when POST request had no JSON body, instead of returning a proper 400 error.

### Root Cause
`request.get_json()` raises an exception when:
1. Request has no Content-Type: application/json header
2. Request body is empty or malformed

Without exception handling, this resulted in a 500 INTERNAL SERVER ERROR.

### Error Message
```
415 Unsupported Media Type: Did not attempt to load JSON data because 
the request Content-Type was not 'application/json'.
```

### Impact
- **Test Failure**: `test_login_no_json_body` expected 400 but got 500
- **User Experience**: Unclear error messages for API clients
- **Debugging**: Harder to diagnose client-side issues

### Solution
Use `get_json()` with flags to safely handle missing JSON:

**File**: `auth.py` (Line 52)

```python
# Before:
data = request.get_json()  # Throws exception if no JSON

# After:
data = request.get_json(force=False, silent=True)  # Returns None if no JSON
if not data or not data.get('email') or not data.get('password'):
    return jsonify({'error': 'Email and password are required'}), 400
```

### Parameters Explanation
- `force=False`: Don't attempt to parse if Content-Type isn't application/json
- `silent=True`: Return None instead of raising exception on parse error

### Test Cases Affected
- ✅ `test_login_no_json_body` (was getting 500, now 400)
- ✅ `test_login_missing_email` 
- ✅ `test_login_missing_password`
- ✅ `test_login_empty_json`

### Verification
```bash
# No JSON body
curl -X POST http://localhost:5000/api/auth/login
# Result: 400 Bad Request ✅

# Empty JSON
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{}'
# Result: 400 Bad Request ✅
```

---

## Fix #2: Missing Password Validation in Login Endpoint

**Issue ID**: BUGFIX-002  
**Date Fixed**: February 21, 2026  
**Severity**: Critical (Security)  
**Status**: ✅ RESOLVED

### Description
The login endpoint was accepting any password for valid user emails. Password validation was commented out, allowing unauthorized access with incorrect credentials.

### Root Cause
The password verification code was commented out during development/testing phase and never restored. The endpoint only checked if the user existed by email, not if the password matched.

```python
# Code was commented out:
# if not verify_password(password, user_password_from_db):
#     return jsonify({'error': 'Invalid credentials'}), 401
```

### Error Behavior
- Invalid password with valid email → **200 OK** (Should be 401)
- Correct password with valid email → **200 OK** ✓ (Correct)

### Impact
- **Security**: Critical vulnerability - anyone could login with correct email and any password
- **Test Failure**: `test_login_invalid_credentials` expected 401 but got 200
- **Business Impact**: Authentication security completely bypassed

### Solution
Implemented simple password validation (for demo; production should use bcrypt/argon2):

**File**: `auth.py` (Lines 64-80)

```python
# Retrieve password from database
cursor.execute("""
    SELECT u.id, u.name, u.email, u.password, r.name as role
    FROM "user" u
    JOIN role r ON u.role_id = r.id
    WHERE u.email = %s AND u.deleted_at IS NULL
    LIMIT 1;
""", (email,))

# Validate password
if password != user_password_from_db:
    return jsonify({'error': 'Invalid credentials'}), 401
```

### Password Handling Note
⚠️ **WARNING**: Passwords in the database are stored in plain text for demonstration purposes. In production:
- Use bcrypt, Argon2, or scrypt for hashing
- Never store plaintext passwords
- Implement proper password reset mechanisms
- Add password complexity requirements

### Test Cases Affected
- ✅ `test_login_invalid_credentials` (was expecting 401)
- ✅ `test_login_successful_*` (all user roles)
- ✅ Prevented unauthorized access attempts

### Verification
```bash
# Valid password
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "chidubem.okoye@student.university.edu", "password": "hashed_pass_se_001"}'
# Result: 200 OK with tokens ✅

# Invalid password
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "chidubem.okoye@student.university.edu", "password": "wrong"}'
# Result: 401 Unauthorized ✅
```

---

## Fix #1: JWT Subject Claim Type Mismatch

**Issue ID**: BUGFIX-001  
**Date Fixed**: February 21, 2026  
**Severity**: Critical  
**Status**: ✅ RESOLVED

### Description
JWT tokens were being created with integer `user_id` for the `sub` (subject) claim, but Flask-JWT-Extended requires the subject to be a string. This caused all protected endpoints to return **422 UNPROCESSABLE ENTITY** errors.

### Root Cause
The `create_access_token()` and `create_refresh_token()` functions in Flask-JWT-Extended validate that the `identity` parameter conforms to JWT standards (RFC 7519). The `sub` claim must be a string, but we were passing an integer.

### Error Message
```
jwt.exceptions.InvalidSubjectError: Subject must be a string
```

### Impact
- **Affected Endpoints**: All protected endpoints (`/api/v1/departments`, `/api/v1/course/*/events`, etc.)
- **Test Failures**: 32 tests failed with 422 status code
- **Business Impact**: Authentication layer completely non-functional for valid users

### Solution
Convert `user_id` to string before token creation:

**File**: `auth.py` (Lines 86-91)

```python
# Before:
access_token = create_access_token(
    identity=user_id,  # Integer
    ...
)

# After:
user_id_str = str(user_id)
access_token = create_access_token(
    identity=user_id_str,  # String
    ...
)
```

### Test Cases Affected
- ✅ `test_get_departments_successful`
- ✅ `test_get_courses_by_department_*` (all variants)
- ✅ `test_get_events_by_course_success`
- ✅ `test_refresh_token_successful`
- ✅ `test_get_current_user_*` (all variants)
- ✅ All integration tests involving protected endpoints

### Verification
```bash
pytest tests/test_auth_endpoints.py::TestAuthRefresh::test_refresh_token_successful -v
# Result: PASSED ✅
```

---

## Test Results Summary

### Before Fixes
```
56 tests collected

❌ FAILURES: 32
✅ PASSED: 24

Failed tests breakdown:
- JWT validation errors (422): ~20 tests
- Password validation (200 vs 401): ~6 tests  
- SQL column errors (500): ~3 tests
- HTTP status expectations: 2 tests
- JSON body handling (500): 1 test
```

### After All Fixes
```
56 tests collected

✅ ALL PASSED: 56
❌ FAILURES: 0

Coverage:
- Authentication endpoints: 20 tests ✅
- API endpoints: 24 tests ✅
- Integration tests: 12 tests ✅
```

### Execution Time
- Before: Avg ~0.15s per test (many failing fast)
- After: Avg ~0.03s per test (all executing fully)
- Total: 56 tests in 1.67s

---

## Code Changes Summary

| File                           | Changes                                                     | Lines | Type     |
| ------------------------------ | ----------------------------------------------------------- | ----- | -------- |
| `auth.py`                      | JWT string conversion + password validation + JSON handling | 40    | Critical |
| `routes.py`                    | SQL column name corrections                                 | 14    | High     |
| `tests/test_auth_endpoints.py` | HTTP status code corrections                                | 4     | Low      |

---

## Lessons Learned & Recommendations

### 1. **Security Best Practices**
- ❌ Never store plaintext passwords
- ✅ Use bcrypt, Argon2, or scrypt for password hashing
- ✅ Implement rate limiting on login endpoint
- ✅ Add password complexity requirements

### 2. **JWT Implementation**
- ✅ Always validate JWT standards (sub claim must be string)
- ✅ Use type hints to catch integer/string mismatches
- ✅ Test with actual JWT validation tools

### 3. **API Design**
- ✅ Match SQL output columns exactly in SELECT statements
- ✅ Document stored procedure return types
- ✅ Use auto-generated API documentation (Swagger/OpenAPI)

### 4. **Testing Standards**
- ✅ Test both success and failure paths
- ✅ Verify HTTP status codes match RFC standards
- ✅ Test edge cases (empty JSON, malformed headers)
- ✅ Use real database data in tests

### 5. **Error Handling**
- ✅ Never let exceptions bubble up without handling
- ✅ Use silent=True for request.get_json() to handle missing data
- ✅ Return appropriate HTTP status codes
- ✅ Provide meaningful error messages

---

## Deployment Checklist

- [x] All 56 tests passing locally
- [ ] Run tests on staging environment
- [ ] Code review of changes
- [ ] Security audit for password handling
- [ ] Update production deployment documentation
- [ ] Monitor error logs post-deployment
- [ ] Implement bcrypt for password hashing (future)

---

## Related Documentation

- [Testing Guide](TESTING.md)
- [Test Suite Summary](TEST_SUITE_SUMMARY.md)
- [Startup Guide](START_HERE.md)

---

## Contact & Questions

For questions about these fixes, refer to:
- Test files: `tests/test_*.py`
- Source files: `auth.py`, `routes.py`
- Database schema: `sql/models.sql`, `sql/statistics.sql`
