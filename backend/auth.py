"""
Authentication module for JWT token management
"""
from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from datetime import timedelta
from config import Config
from database import Database

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/login', methods=['POST'])
def login() -> tuple:
    """
    Authenticate user and return JWT tokens
    ---
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            email:
              type: string
              example: "student@university.edu"
            password:
              type: string
              example: "password123"
    responses:
      200:
        description: Login successful, returns access and refresh tokens
        schema:
          type: object
          properties:
            access_token:
              type: string
            refresh_token:
              type: string
            user_id:
              type: integer
            user_name:
              type: string
            role:
              type: string
      401:
        description: Invalid credentials
      400:
        description: Missing required fields
    """
    try:
        data = request.get_json(force=False, silent=True)
        
        # Validate input
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        email = data.get('email')
        password = data.get('password')
        
        # Query user from database with role name
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT u.id, u.name, u.email, u.password, r.name as role
                FROM "user" u
                JOIN role r ON u.role_id = r.id
                WHERE u.email = %s AND u.deleted_at IS NULL
                LIMIT 1;
            """, (email,))
            user = cursor.fetchone()
        
        # Check if user exists
        if not user:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # For demo purposes - simple password check
        # In production use proper password hashing (bcrypt, argon2)
        user_password_from_db = user.get('password')
        if password != user_password_from_db:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        user_id = user['id']
        user_name = user['name']
        user_role = user['role']
        
        # Create JWT tokens
        # Convert user_id to string for JWT 'sub' claim (must be string)
        user_id_str = str(user_id)
        access_token = create_access_token(
            identity=user_id_str,
            expires_delta=timedelta(seconds=Config.JWT_ACCESS_TOKEN_EXPIRES),
            additional_claims={'user_name': user_name, 'role': user_role}
        )
        
        refresh_token = create_refresh_token(identity=user_id_str)
        
        return jsonify({
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user_id': user_id,
            'user_name': user_name,
            'role': user_role,
            'expires_in': Config.JWT_ACCESS_TOKEN_EXPIRES
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """
    Refresh access token using refresh token
    ---
    security:
      - Bearer: []
    parameters:
      - name: Authorization
        in: header
        type: string
        required: true
        description: "Bearer <refresh_token>"
    responses:
      200:
        description: New access token generated
        schema:
          type: object
          properties:
            access_token:
              type: string
              example: "eyJ0eXAiOiJKV1QiLCJhbGc..."
            expires_in:
              type: integer
              example: 3600
      401:
        description: Invalid or expired refresh token
        schema:
          type: object
          properties:
            error:
              type: string
              example: "Invalid or expired refresh token"
    """
    try:
        user_id = get_jwt_identity()
        
        # Get user details for claims
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT u.name, r.name as role FROM "user" u
                JOIN role r ON u.role_id = r.id
                WHERE u.id = %s AND u.deleted_at IS NULL
            """, (user_id,))
            user = cursor.fetchone()
        
        if not user:
            return jsonify({'error': 'User not found'}), 401
        
        # Create new access token
        access_token = create_access_token(
            identity=user_id,
            expires_delta=timedelta(seconds=Config.JWT_ACCESS_TOKEN_EXPIRES),
            additional_claims={'user_name': user['name'], 'role': user['role']}
        )
        
        return jsonify({
            'access_token': access_token,
            'expires_in': Config.JWT_ACCESS_TOKEN_EXPIRES
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """
    Get current authenticated user information
    ---
    security:
      - Bearer: []
    parameters:
      - name: Authorization
        in: header
        type: string
        required: true
        description: "Bearer <access_token>"
    responses:
      200:
        description: Current user information
        schema:
          type: object
          properties:
            user_id:
              type: integer
              example: 1
            user_name:
              type: string
              example: "John Doe"
            email:
              type: string
              example: "john@university.edu"
            role:
              type: string
              example: "Student"
      401:
        description: Unauthorized or missing Authorization header
        schema:
          type: object
          properties:
            error:
              type: string
              example: "Missing Authorization Header"
    """
    try:
        user_id = get_jwt_identity()
        
        with Database.get_cursor() as cursor:
            cursor.execute("""
                SELECT u.id, u.name, u.email, r.name as role
                FROM "user" u
                JOIN role r ON u.role_id = r.id
                WHERE u.id = %s AND u.deleted_at IS NULL
            """, (user_id,))
            user = cursor.fetchone()
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({
            'user_id': user['id'],
            'user_name': user['name'],
            'email': user['email'],
            'role': user['role']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
