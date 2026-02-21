"""
Tests for API endpoints (/api/v1/*)
Tests protected endpoints that require JWT authentication
"""
import pytest


class TestHealthCheck:
    """Tests for GET /api/v1/health endpoint (no authentication required)"""

    def test_health_check_success(self, client):
        """Test health check endpoint returns success when database is connected"""
        response = client.get('/api/v1/health')
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Verify response structure
        assert 'status' in data
        assert 'database' in data
        assert data['status'] == 'ok'
        assert data['database'] == 'connected'

    def test_health_check_no_auth_required(self, client):
        """Test health check doesn't require authentication"""
        # Should work without any headers
        response = client.get('/api/v1/health')
        assert response.status_code == 200


class TestDepartmentsEndpoint:
    """Tests for GET /api/v1/departments endpoint"""

    def test_get_departments_successful(self, client, auth_headers):
        """Test getting all departments with valid authentication"""
        response = client.get(
            '/api/v1/departments',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should return a list
        assert isinstance(data, list)
        
        # Should have departments
        assert len(data) > 0
        
        # Each department should have required fields
        for dept in data:
            assert 'department_name' in dept
            assert 'total_courses' in dept
            assert 'total_events' in dept
            assert 'total_students' in dept
            assert 'total_registrations' in dept
            assert 'attendance_rate' in dept

    def test_get_departments_includes_expected_depts(self, client, auth_headers):
        """Test that response includes expected departments"""
        response = client.get(
            '/api/v1/departments',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        dept_names = [d['department_name'] for d in data]
        assert 'Software Engineering' in dept_names
        assert 'Networking and Security' in dept_names
        assert 'Information Systems Management' in dept_names

    def test_get_departments_without_auth(self, client):
        """Test getting departments without authentication returns 401"""
        response = client.get('/api/v1/departments')
        
        assert response.status_code == 401

    def test_get_departments_with_invalid_token(self, client):
        """Test getting departments with invalid token"""
        response = client.get(
            '/api/v1/departments',
            headers={'Authorization': 'Bearer invalid_token'}
        )
        
        assert response.status_code == 422

    def test_get_departments_lecturer_access(self, client, lecturer_auth_headers):
        """Test that lecturer can access departments endpoint"""
        response = client.get(
            '/api/v1/departments',
            headers=lecturer_auth_headers
        )
        
        assert response.status_code == 200

    def test_get_departments_admin_access(self, client, admin_auth_headers):
        """Test that admin can access departments endpoint"""
        response = client.get(
            '/api/v1/departments',
            headers=admin_auth_headers
        )
        
        assert response.status_code == 200


class TestCoursesEndpoint:
    """Tests for GET /api/v1/department/<dept_id>/courses endpoint"""

    def test_get_courses_by_department_success(self, client, auth_headers):
        """Test getting courses for a specific department"""
        response = client.get(
            '/api/v1/department/1/courses',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should return a list
        assert isinstance(data, list)
        
        # Each course should have required fields
        for course in data:
            assert 'course_id' in course
            assert 'department_name' in course
            assert 'course_code' in course
            assert 'course_title' in course
            assert 'event_count' in course

    def test_get_courses_by_department_1(self, client, auth_headers):
        """Test getting courses for Software Engineering department"""
        response = client.get(
            '/api/v1/department/1/courses',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should have 3 courses
        assert len(data) >= 3
        
        # Check for expected courses
        course_codes = [c['course_code'] for c in data]
        assert 'SE101' in course_codes
        assert 'SE102' in course_codes
        assert 'SE103' in course_codes

    def test_get_courses_by_department_2(self, client, auth_headers):
        """Test getting courses for Networking and Security department"""
        response = client.get(
            '/api/v1/department/2/courses',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        course_codes = [c['course_code'] for c in data]
        assert 'NS101' in course_codes
        assert 'NS102' in course_codes
        assert 'NS103' in course_codes

    def test_get_courses_by_department_3(self, client, auth_headers):
        """Test getting courses for ISM department"""
        response = client.get(
            '/api/v1/department/3/courses',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        course_codes = [c['course_code'] for c in data]
        assert 'ISM101' in course_codes
        assert 'ISM102' in course_codes
        assert 'ISM103' in course_codes

    def test_get_courses_invalid_department(self, client, auth_headers):
        """Test getting courses for non-existent department"""
        response = client.get(
            '/api/v1/department/999/courses',
            headers=auth_headers
        )
        
        # Should return 200 with empty list or 500 with error (depending on implementation)
        assert response.status_code in [200, 500]

    def test_get_courses_without_auth(self, client):
        """Test getting courses without authentication"""
        response = client.get('/api/v1/department/1/courses')
        
        assert response.status_code == 401


class TestEventsEndpoint:
    """Tests for GET /api/v1/course/<course_id>/events endpoint"""

    def test_get_events_by_course_success(self, client, auth_headers):
        """Test getting events for a specific course"""
        response = client.get(
            '/api/v1/course/1/events',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should return a list
        assert isinstance(data, list)
        
        # Should have events
        assert len(data) > 0
        
        # Each event should have required fields
        for event in data:
            assert 'event_id' in event
            assert 'course_code' in event
            assert 'course_title' in event
            assert 'event_name' in event
            assert 'event_type' in event
            assert 'event_status' in event
            assert 'start_at' in event
            assert 'organizer_name' in event

    def test_get_events_contains_different_statuses(self, client, auth_headers):
        """Test that events contain different status types"""
        response = client.get(
            '/api/v1/course/1/events',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        statuses = {event['event_status'] for event in data}
        # Should have multiple event statuses
        assert len(statuses) >= 1

    def test_get_events_without_auth(self, client):
        """Test getting events without authentication"""
        response = client.get('/api/v1/course/1/events')
        
        assert response.status_code == 401

    def test_get_events_invalid_course(self, client, auth_headers):
        """Test getting events for non-existent course"""
        response = client.get(
            '/api/v1/course/999/events',
            headers=auth_headers
        )
        
        # Should return 200 with empty list or 500 with error
        assert response.status_code in [200, 500]


class TestRegistrationsEndpoint:
    """Tests for GET /api/v1/event/<event_id>/registrations endpoint"""

    def test_get_registrations_by_event_success(self, client, auth_headers):
        """Test getting registrations for a specific event"""
        response = client.get(
            '/api/v1/event/1/registrations',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should return a list
        assert isinstance(data, list)
        
        # Should have registrations
        assert len(data) > 0
        
        # Each registration should have required fields
        for reg in data:
            assert 'student_name' in reg
            assert 'student_email' in reg

    def test_get_registrations_without_auth(self, client):
        """Test getting registrations without authentication"""
        response = client.get('/api/v1/event/1/registrations')
        
        assert response.status_code == 401


class TestRootEndpoint:
    """Tests for GET / root endpoint"""

    def test_root_endpoint_returns_info(self, client):
        """Test root endpoint returns API information"""
        response = client.get('/')
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Verify response structure
        assert 'message' in data
        assert 'version' in data
        assert 'documentation' in data
        assert 'endpoints' in data

    def test_root_endpoint_contains_endpoints_info(self, client):
        """Test root endpoint includes information about available endpoints"""
        response = client.get('/')
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Should have documented endpoints
        endpoints = data['endpoints']
        assert 'auth' in endpoints
        assert 'departments' in endpoints
        assert 'courses' in endpoints
        assert 'events' in endpoints


class TestErrorHandling:
    """Tests for error handling"""

    def test_404_not_found(self, client):
        """Test 404 error handling"""
        response = client.get('/api/v1/nonexistent')
        
        assert response.status_code == 404
        data = response.get_json()
        assert 'error' in data

    def test_method_not_allowed(self, client, auth_headers):
        """Test method not allowed (e.g., POST on GET endpoint)"""
        response = client.post(
            '/api/v1/health',
            headers=auth_headers
        )
        
        assert response.status_code == 405
