"""
Pytest configuration and shared fixtures for testing
"""
import pytest
import os
from dotenv import load_dotenv

# Load test environment variables
load_dotenv()

from app import create_app
from database import Database
from config import Config


class TestConfig(Config):
    """Test configuration"""
    TESTING = True
    JWT_ACCESS_TOKEN_EXPIRES = 3600


@pytest.fixture(scope='session')
def app():
    """Create application for testing"""
    app = create_app()
    app.config.from_object(TestConfig)
    return app


@pytest.fixture
def client(app):
    """Create test client"""
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create CLI runner for testing Flask CLI commands"""
    return app.test_cli_runner()


@pytest.fixture
def auth_headers(client):
    """
    Create authentication headers with valid JWT token
    Uses a known student from test data: chidubem.okoye@student.university.edu
    """
    response = client.post(
        '/api/auth/login',
        json={
            'email': 'chidubem.okoye@student.university.edu',
            'password': 'hashed_pass_se_001'
        }
    )
    
    if response.status_code == 200:
        data = response.get_json()
        return {
            'Authorization': f"Bearer {data['access_token']}"
        }
    
    return {}


@pytest.fixture
def lecturer_auth_headers(client):
    """
    Create authentication headers with valid JWT token for lecturer
    Uses: emily.johnson@university.edu
    """
    response = client.post(
        '/api/auth/login',
        json={
            'email': 'emily.johnson@university.edu',
            'password': 'hashed_password_1'
        }
    )
    
    if response.status_code == 200:
        data = response.get_json()
        return {
            'Authorization': f"Bearer {data['access_token']}"
        }
    
    return {}


@pytest.fixture
def admin_auth_headers(client):
    """
    Create authentication headers with valid JWT token for admin
    Uses: admin@university.edu
    """
    response = client.post(
        '/api/auth/login',
        json={
            'email': 'admin@university.edu',
            'password': 'hashed_password_admin'
        }
    )
    
    if response.status_code == 200:
        data = response.get_json()
        return {
            'Authorization': f"Bearer {data['access_token']}"
        }
    
    return {}


# Test data constants
TEST_USERS = {
    'student': {
        'email': 'chidubem.okoye@student.university.edu',
        'password': 'hashed_pass_se_001',
        'name': 'Chidubem Okoye',
        'role': 'Student'
    },
    'lecturer': {
        'email': 'emily.johnson@university.edu',
        'password': 'hashed_password_1',
        'name': 'Dr. Emily Johnson',
        'role': 'Lecturer'
    },
    'admin': {
        'email': 'admin@university.edu',
        'password': 'hashed_password_admin',
        'name': 'Admin User',
        'role': 'Administrator'
    }
}


@pytest.fixture
def app_context(app):
    """Push application context for database operations"""
    with app.app_context():
        yield app
