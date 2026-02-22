from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flasgger import Swagger
from config import Config
from routes import api
from auth import auth_bp


def create_app() -> Flask:
    """Application factory"""
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Initialize CORS - Allow all origins for development
    CORS(app, 
         resources={r"/*": {
             "origins": "*",
             "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
             "allow_headers": ["Content-Type", "Authorization"]
         }},
         expose_headers=["Content-Type"])
    
    # Initialize JWT
    jwt = JWTManager(app)
    
    # Initialize Swagger UI
    swagger = Swagger(app, template={
        "swagger": "2.0",
        "info": {
            "title": "Attendance Management System API",
            "version": "1.0.0",
            "description": "RESTful API for querying attendance database statistics using PostgreSQL stored procedures"
        },
        "securityDefinitions": {
            "Bearer": {
                "type": "apiKey",
                "name": "Authorization",
                "in": "header",
                "description": "JWT Authorization header using Bearer scheme. Example: 'Authorization: Bearer {token}'"
            }
        },
        "security": [
            {"Bearer": []}
        ]
    })
    
    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(api)
    
    @app.route('/')
    def index():
        """Root endpoint with API documentation"""
        return jsonify({
            'message': 'Attendance Management System API',
            'version': '1.0.0',
            'documentation': 'http://localhost:5000/apidocs',
            'endpoints': {
                'auth': {
                    'POST /api/auth/login': 'Login and get JWT token',
                    'POST /api/auth/refresh': 'Refresh JWT token'
                },
                'departments': {
                    'GET /api/v1/departments': 'Get all departments with statistics'
                },
                'courses': {
                    'GET /api/v1/courses': 'Get statistics for all courses',
                    'GET /api/v1/department/<dept_id>/courses': 'Get courses for a department'
                },
                'events': {
                    'GET /api/v1/course/<course_id>/events': 'Get events for a course'
                },
                'registrations': {
                    'GET /api/v1/event/<event_id>/registrations': 'Get registrations for an event'
                },
                'statistics': {
                    'GET /api/v1/course/<course_id>/statistics': 'Get statistics for a course',
                    'GET /api/v1/student/<student_id>/attendance': 'Get attendance summary for a student'
                },
                'health': {
                    'GET /api/v1/health': 'Health check'
                }
            }
        })
    
    @app.errorhandler(404)
    def not_found(error) -> tuple:
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def server_error(error) -> tuple:
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
