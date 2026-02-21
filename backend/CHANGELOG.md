# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-RC1] - 2026-02-21

### 🔧 Fixed

#### Critical Fixes
- **JWT Token Subject Claim**: Fixed JWT creation to use string identity instead of integer for `sub` claim, resolving all 422 UNPROCESSABLE ENTITY errors on protected endpoints (#BUGFIX-001)
- **Password Validation**: Implemented password verification in login endpoint, preventing unauthorized access with incorrect credentials (#BUGFIX-002)
- **SQL Column Mapping**: Corrected column names in events endpoint SELECT statement to match `get_events_by_course()` stored procedure output (#BUGFIX-004)

#### API Fixes
- **JSON Body Handling**: Added safe JSON parsing with proper error handling for requests without JSON body (#BUGFIX-003)
- **HTTP Status Codes**: Updated test expectations for malformed headers from 422 to 401, aligning with HTTP standards (#BUGFIX-005)

#### Test Improvements
- ✅ All 56 tests now passing (previously 24 passed, 32 failed)
- ✅ Added comprehensive test coverage for authentication flows
- ✅ Integration tests verifying multi-user role access patterns
- ✅ API endpoint validation tests with proper error handling

### 📊 Test Coverage

| Category       | Tests  | Status     |
| -------------- | ------ | ---------- |
| Authentication | 20     | ✅ PASS     |
| API Endpoints  | 24     | ✅ PASS     |
| Integration    | 12     | ✅ PASS     |
| **Total**      | **56** | **✅ PASS** |

### 📝 Documentation

- Added comprehensive [BUGFIXES.md](BUGFIXES.md) documenting all fixes with root cause analysis
- Updated test documentation with fixes summary
- Added deployment checklist and security recommendations

### ⚠️ Known Issues & Future Work

1. **Password Security** (High Priority)
   - Passwords currently stored in plaintext in database
   - Recommendation: Implement bcrypt/Argon2 hashing in next release
   - Impact: Production deployment must address this before launch

2. **Rate Limiting** (Medium Priority)
   - No rate limiting on authentication endpoints
   - Recommendation: Add rate limiting to prevent brute force attacks
   - Target: v1.0.1

3. **CORS Configuration** (Low Priority)
   - Currently allows all origins (`"origins": "*"`)
   - Recommendation: Restrict to specific frontend domain
   - Target: v1.0.1

---

## [0.9.0] - 2026-02-20

### ✨ Added

- Initial Flask application setup with PostgreSQL integration
- JWT authentication implementation with access and refresh tokens
- Test suite with 56 comprehensive test cases
- API endpoints for:
  - Department statistics
  - Course information by department
  - Event details by course
  - Event registrations
  - Student attendance tracking
- Swagger/Flasgger API documentation
- PostgreSQL stored procedures for statistics and reporting

### 🏗️ Architecture

- Flask application with blueprints for modular structure
- JWT-Extended for token-based authentication
- Flask-CORS for cross-origin requests
- PostgreSQL database with role-based access control
- pytest with pytest-flask for comprehensive testing

### 📋 Features

- Role-based access control (Student, Lecturer, Administrator)
- Token refresh mechanism for extended sessions
- Database connection pooling
- Error handling and validation
- API documentation via Swagger UI

---

## Version History

### Unreleased (In Development)
- [ ] Password hashing with bcrypt
- [ ] Rate limiting on auth endpoints
- [ ] Enhanced CORS configuration
- [ ] Request logging and monitoring
- [ ] API versioning strategy

---

## Deprecation Notices

### None Currently

---

## Security Notices

### ⚠️ Critical: Password Storage

**Current State**: Passwords stored in plaintext (demonstration only)

**Action Required**: Before production deployment, implement:
1. Password hashing with bcrypt or Argon2
2. Salt generation for each password
3. Minimum password complexity requirements
4. Secure password reset mechanism
5. Password history tracking

**Timeline**: Must be completed before v1.0.0 production release

---

## Migration Guide

### From 0.9.0 to 1.0.0-RC1

No database schema changes required. All fixes are backward compatible.

**Required Actions**:
1. Deploy updated `auth.py` with password validation
2. Deploy updated `routes.py` with corrected SQL columns
3. Run test suite to verify: `pytest tests/`
4. Expected result: 56 tests passing

**Rollback**: If issues occur, revert to commit before this release and investigate.

---

## Support

For issues or questions:
1. Check [BUGFIXES.md](BUGFIXES.md) for detailed fix documentation
2. Review [TESTING.md](TESTING.md) for testing guidelines
3. See [START_HERE.md](START_HERE.md) for setup instructions
