"""
Tests for authentication endpoints (/api/auth/*)
Following Flask testing best practices with fixtures and comprehensive coverage
"""
import pytest
from flask_jwt_extended import decode_token
from config import Config


class TestAuthLogin:
    """Tests for POST /api/auth/login endpoint"""

    def test_login_successful_student(self, client):
        """Test successful login with valid student credentials"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'hashed_pass_se_001'
            }
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Verify response structure
        assert 'access_token' in data
        assert 'refresh_token' in data
        assert 'user_id' in data
        assert 'user_name' in data
        assert 'role' in data
        assert 'expires_in' in data
        
        # Verify token values
        assert data['user_name'] == 'Chidubem Okoye'
        assert data['role'] == 'Student'
        assert data['expires_in'] == Config.JWT_ACCESS_TOKEN_EXPIRES

    def test_login_successful_lecturer(self, client):
        """Test successful login with valid lecturer credentials"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'emily.johnson@university.edu',
                'password': 'hashed_password_1'
            }
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['user_name'] == 'Dr. Emily Johnson'
        assert data['role'] == 'Lecturer'

    def test_login_successful_admin(self, client):
        """Test successful login with valid admin credentials"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'admin@university.edu',
                'password': 'hashed_password_admin'
            }
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['user_name'] == 'Admin User'
        assert data['role'] == 'Administrator'

    def test_login_invalid_credentials(self, client):
        """Test login with incorrect password"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'wrong_password'
            }
        )
        
        assert response.status_code == 401
        data = response.get_json()
        assert 'error' in data

    def test_login_nonexistent_user(self, client):
        """Test login with non-existent email"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'nonexistent@university.edu',
                'password': 'password123'
            }
        )
        
        assert response.status_code == 401
        data = response.get_json()
        assert 'error' in data

    def test_login_missing_email(self, client):
        """Test login without email field"""
        response = client.post(
            '/api/auth/login',
            json={'password': 'password123'}
        )
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data
        assert 'required' in data['error'].lower()

    def test_login_missing_password(self, client):
        """Test login without password field"""
        response = client.post(
            '/api/auth/login',
            json={'email': 'chidubem.okoye@student.university.edu'}
        )
        
        assert response.status_code == 400
        data = response.get_json()
        assert 'error' in data
        assert 'required' in data['error'].lower()

    def test_login_empty_json(self, client):
        """Test login with empty JSON body"""
        response = client.post(
            '/api/auth/login',
            json={}
        )
        
        assert response.status_code == 400

    def test_login_no_json_body(self, client):
        """Test login without JSON body"""
        response = client.post('/api/auth/login')
        
        assert response.status_code == 400

    def test_login_returns_valid_jwt_token(self, client):
        """Test that login returns a valid JWT token"""
        response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'hashed_pass_se_001'
            }
        )
        
        assert response.status_code == 200
        data = response.get_json()
        access_token = data['access_token']
        
        # Verify token is a valid JWT
        try:
            decoded = decode_token(access_token)
            assert decoded['sub'] is not None  # sub is the user_id
            assert 'user_name' in decoded
            assert 'role' in decoded
        except Exception as e:
            pytest.fail(f"Token decoding failed: {e}")


class TestAuthRefresh:
    """Tests for POST /api/auth/refresh endpoint"""

    def test_refresh_token_successful(self, client):
        """Test successful token refresh with valid refresh token"""
        # First login to get tokens
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'chidubem.okoye@student.university.edu',
                'password': 'hashed_pass_se_001'
            }
        )
        
        refresh_token = login_response.get_json()['refresh_token']
        
        # Now refresh the token
        response = client.post(
            '/api/auth/refresh',
            headers={'Authorization': f'Bearer {refresh_token}'}
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Verify response structure
        assert 'access_token' in data
        assert 'expires_in' in data
        assert data['expires_in'] == Config.JWT_ACCESS_TOKEN_EXPIRES

    def test_refresh_token_without_header(self, client):
        """Test refresh without Authorization header"""
        response = client.post('/api/auth/refresh')
        
        assert response.status_code == 401

    def test_refresh_token_invalid_token(self, client):
        """Test refresh with invalid token"""
        response = client.post(
            '/api/auth/refresh',
            headers={'Authorization': 'Bearer invalid_token_here'}
        )
        
        assert response.status_code == 422  # Unprocessable Entity (invalid JWT)

    def test_refresh_token_expired_in_future(self, client):
        """Test refresh returns a new valid access token"""
        login_response = client.post(
            '/api/auth/login',
            json={
                'email': 'emily.johnson@university.edu',
                'password': 'hashed_password_1'
            }
        )
        
        refresh_token = login_response.get_json()['refresh_token']
        
        response = client.post(
            '/api/auth/refresh',
            headers={'Authorization': f'Bearer {refresh_token}'}
        )
        
        assert response.status_code == 200
        new_token = response.get_json()['access_token']
        
        # Verify new token can be used
        try:
            decoded = decode_token(new_token)
            assert decoded['sub'] is not None
        except Exception as e:
            pytest.fail(f"New token validation failed: {e}")

    def test_refresh_with_malformed_header(self, client):
        """Test refresh with malformed Authorization header"""
        response = client.post(
            '/api/auth/refresh',
            headers={'Authorization': 'InvalidHeader token'}
        )
        
        # Malformed auth header should return 401 (Unauthorized), not 422
        assert response.status_code == 401


class TestAuthMe:
    """Tests for GET /api/auth/me endpoint"""

    def test_get_current_user_successful(self, client, auth_headers):
        """Test getting current user info with valid token"""
        response = client.get(
            '/api/auth/me',
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        # Verify response structure
        assert 'user_id' in data
        assert 'user_name' in data
        assert 'email' in data
        assert 'role' in data
        
        # Verify correct user data
        assert data['user_name'] == 'Chidubem Okoye'
        assert data['email'] == 'chidubem.okoye@student.university.edu'
        assert data['role'] == 'Student'

    def test_get_current_user_lecturer(self, client, lecturer_auth_headers):
        """Test getting lecturer user info"""
        response = client.get(
            '/api/auth/me',
            headers=lecturer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['user_name'] == 'Dr. Emily Johnson'
        assert data['role'] == 'Lecturer'

    def test_get_current_user_admin(self, client, admin_auth_headers):
        """Test getting admin user info"""
        response = client.get(
            '/api/auth/me',
            headers=admin_auth_headers
        )
        
        assert response.status_code == 200
        data = response.get_json()
        
        assert data['user_name'] == 'Admin User'
        assert data['role'] == 'Administrator'

    def test_get_current_user_without_token(self, client):
        """Test getting user info without authentication"""
        response = client.get('/api/auth/me')
        
        assert response.status_code == 401

    def test_get_current_user_invalid_token(self, client):
        """Test getting user info with invalid token"""
        response = client.get(
            '/api/auth/me',
            headers={'Authorization': 'Bearer invalid_token'}
        )
        
        assert response.status_code == 422

    def test_get_current_user_malformed_header(self, client):
        """Test getting user info with malformed Authorization header"""
        response = client.get(
            '/api/auth/me',
            headers={'Authorization': 'InvalidFormat token'}
        )
        
        # Malformed auth header should return 401 (Unauthorized), not 422
        assert response.status_code == 401
