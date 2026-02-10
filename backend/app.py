from flask import Flask, jsonify
from flasgger import Swagger
from config import Config
from routes import api


def create_app():
    """Application factory"""
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Initialize Swagger UI
    swagger = Swagger(app, template={
        "swagger": "2.0",
        "info": {
            "title": "Attendance Management System API",
            "version": "1.0.0",
            "description": "RESTful API for querying attendance database statistics using PostgreSQL stored procedures"
        }
    })
    
    # Register blueprints
    app.register_blueprint(api)
    
    @app.route('/')
    def index():
        """Root endpoint with API documentation"""
        return jsonify({
            'message': 'Attendance Management System API',
            'version': '1.0.0',
            'endpoints': {
                'departments': {
                    'GET /api/departments': 'Get all departments with statistics'
                },
                'courses': {
                    'GET /api/courses': 'Get statistics for all courses',
                    'GET /api/department/<dept_id>/courses': 'Get courses for a department'
                },
                'events': {
                    'GET /api/course/<course_id>/events': 'Get events for a course'
                },
                'registrations': {
                    'GET /api/event/<event_id>/registrations': 'Get registrations for an event'
                },
                'statistics': {
                    'GET /api/course/<course_id>/statistics': 'Get statistics for a course',
                    'GET /api/student/<student_id>/attendance': 'Get attendance summary for a student'
                },
                'health': {
                    'GET /api/health': 'Health check'
                }
            }
        })
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def server_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
