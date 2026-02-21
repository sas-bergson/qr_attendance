"""
Integration tests for all API endpoints
Tests real database interactions with comprehensive scenarios
"""
import pytest


class TestFullAuthenticationFlow:
    """Tests for complete authentication workflows"""

    def test_complete_auth_flow_login_and_access_protected_resource(self, client):
        """
        Test full authentication flow:
        1. Login
        2. Get access token
        3. Use token to access protected resource
        4. Verify correct user data
        """
        # Step 1: Login
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'emily.johnson@university.edu',
                'password': 'hashed_password_1'
            }
        )
        assert login_response.status_code == 200
        
        access_token = login_response.get_json()['access_token']
        
        # Step 2: Use token to access protected resource
        headers = {'Authorization': f'Bearer {access_token}'}
        protected_response = client.get(
            '/api/auth/me',
            headers=headers
        )
        
        assert protected_response.status_code == 200
        user_data = protected_response.get_json()
        assert user_data['user_name'] == 'Dr. Emily Johnson'
        assert user_data['role'] == 'Lecturer'

    def test_complete_workflow_login_refresh_access_resource(self, client):
        """
        Test complete workflow:
        1. Login
        2. Refresh token
        3. Use new token to access resource
        """
        # Step 1: Login
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'admin@university.edu',
                'password': 'hashed_password_admin'
            }
        )
        assert login_response.status_code == 200
        
        refresh_token = login_response.get_json()['refresh_token']
        
        # Step 2: Refresh token
        refresh_response = client.post(
            '/api/auth/refresh',
            headers={'Authorization': f'Bearer {refresh_token}'}
        )
        assert refresh_response.status_code == 200
        
        new_access_token = refresh_response.get_json()['access_token']
        
        # Step 3: Use new token to access protected resource
        protected_response = client.get(
            '/api/auth/me',
            headers={'Authorization': f'Bearer {new_access_token}'}
        )
        
        assert protected_response.status_code == 200
        user_data = protected_response.get_json()
        assert user_data['user_name'] == 'Admin User'


class TestMultipleUserRoles:
    """Tests to verify different user roles have appropriate access"""

    def test_student_can_access_departments(self, client):
        """Verify student role can access departments endpoint"""
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'hashed_pass_se_001'
            }
        )
        
        access_token = login_response.get_json()['access_token']
        headers = {'Authorization': f'Bearer {access_token}'}
        
        response = client.get('/api/v1/departments', headers=headers)
        assert response.status_code == 200

    def test_lecturer_can_access_departments(self, client):
        """Verify lecturer role can access departments endpoint"""
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'emily.johnson@university.edu',
                'password': 'hashed_password_1'
            }
        )
        
        access_token = login_response.get_json()['access_token']
        headers = {'Authorization': f'Bearer {access_token}'}
        
        response = client.get('/api/v1/departments', headers=headers)
        assert response.status_code == 200

    def test_admin_can_access_departments(self, client):
        """Verify admin role can access departments endpoint"""
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'admin@university.edu',
                'password': 'hashed_password_admin'
            }
        )
        
        access_token = login_response.get_json()['access_token']
        headers = {'Authorization': f'Bearer {access_token}'}
        
        response = client.get('/api/v1/departments', headers=headers)
        assert response.status_code == 200

    def test_student_can_access_courses(self, client):
        """Verify student role can access courses endpoint"""
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'amara.nwankwo@student.university.edu',
                'password': 'hashed_pass_se_002'
            }
        )
        
        access_token = login_response.get_json()['access_token']
        headers = {'Authorization': f'Bearer {access_token}'}
        
        response = client.get('/api/v1/department/1/courses', headers=headers)
        assert response.status_code == 200


class TestDataConsistency:
    """Tests to verify data consistency across endpoints"""

    def test_department_count_consistency(self, client, auth_headers):
        """Verify department count is consistent"""
        response = client.get('/api/v1/departments', headers=auth_headers)
        assert response.status_code == 200
        
        data = response.get_json()
        # Should have exactly 3 departments
        assert len(data) == 3

    def test_course_data_contains_non_zero_events(self, client, auth_headers):
        """Verify courses have event count information"""
        response = client.get('/api/v1/department/1/courses', headers=auth_headers)
        assert response.status_code == 200
        
        data = response.get_json()
        for course in data:
            # Event count should be > 0
            assert course['event_count'] > 0

    def test_event_data_structure(self, client, auth_headers):
        """Verify events have all required data fields"""
        response = client.get('/api/v1/course/1/events', headers=auth_headers)
        assert response.status_code == 200
        
        data = response.get_json()
        required_fields = [
            'event_id', 'course_code', 'course_title', 'event_name',
            'event_type', 'event_status', 'start_at', 'organizer_name'
        ]
        
        for event in data:
            for field in required_fields:
                assert field in event


class TestContentTypes:
    """Tests to verify correct content types in responses"""

    def test_json_content_type_in_responses(self, client, auth_headers):
        """Verify all endpoints return JSON content type"""
        endpoints = [
            '/api/auth/me',
            '/api/v1/health',
            '/api/v1/departments',
        ]
        
        for endpoint in endpoints:
            response = client.get(endpoint, headers=auth_headers)
            assert 'application/json' in response.content_type

    def test_json_content_type_in_auth_responses(self, client):
        """Verify authentication endpoints return JSON"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'hashed_pass_se_001'
            }
        )
        
        assert 'application/json' in response.content_type
