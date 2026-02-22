import psycopg2
from typing import Generator
from psycopg2.extensions import connection as Connection
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from flask import current_app


class Database:
    """Database connection handler"""
    
    @staticmethod
    def get_connection() -> Connection:
        """Create a database connection"""
        return psycopg2.connect(
            host=current_app.config['DB_HOST'],
            port=current_app.config['DB_PORT'],
            database=current_app.config['DB_NAME'],
            user=current_app.config['DB_USER'],
            password=current_app.config['DB_PASSWORD']
        )
    
    @staticmethod
    @contextmanager
    def get_cursor(commit=False) -> Generator:
        """Context manager for database cursor"""
        conn = Database.get_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cursor
            if commit:
                conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()


def dict_from_cursor(cursor) -> list[dict]:
    """Convert cursor results to list of dictionaries"""
    # RealDictCursor already returns dictionaries, just convert to list
    return [dict(row) for row in cursor.fetchall()]
