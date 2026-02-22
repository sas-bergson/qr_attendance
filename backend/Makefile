.PHONY: test test-verbose test-auth test-api test-integration test-coverage test-coverage-html help

help:
	@echo "Flask Attendance System - Test Commands"
	@echo "========================================"
	@echo "make test              - Run all tests"
	@echo "make test-verbose      - Run all tests with verbose output"
	@echo "make test-auth         - Run authentication tests only"
	@echo "make test-api          - Run API endpoint tests only"
	@echo "make test-integration  - Run integration tests only"
	@echo "make test-coverage     - Run tests with coverage report (terminal)"
	@echo "make test-coverage-html - Run tests with HTML coverage report"
	@echo "make test-quick        - Run fast tests only"

test:
	./venv/bin/python -m pytest

test-verbose:
	./venv/bin/python -m pytest -v

test-auth:
	./venv/bin/python -m pytest tests/test_auth_endpoints.py -v

test-api:
	./venv/bin/python -m pytest tests/test_api_endpoints.py -v

test-integration:
	./venv/bin/python -m pytest tests/test_integration.py -v

test-coverage:
	./venv/bin/python -m pytest --cov=app --cov=routes --cov=auth --cov-report=term-missing

test-coverage-html:
	./venv/bin/python -m pytest --cov=app --cov=routes --cov=auth --cov-report=html
	@echo "Coverage report generated in htmlcov/index.html"

test-quick:
	./venv/bin/python -m pytest -m "not slow"

test-watch:
	./venv/bin/python -m pytest_watch

clean-coverage:
	rm -rf htmlcov/ .coverage

clean-pytest:
	rm -rf .pytest_cache/ __pycache__/ tests/__pycache__/

clean: clean-coverage clean-pytest
