#!/bin/bash
# Quick Start Script for Running Tests
# Usage: ./run_tests.sh [option]
# Run from: backend/ directory

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Flask Attendance System - Test Quick Start                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "❌ pytest is not installed"
    echo "Installing testing dependencies..."
    pip install -r requirements.txt
fi

# Show menu if no argument provided
if [ $# -eq 0 ]; then
    echo "Available commands:"
    echo ""
    echo "  1) Run all tests"
    echo "  2) Run tests (verbose)"
    echo "  3) Run auth tests only"
    echo "  4) Run API tests only"
    echo "  5) Run integration tests only"
    echo "  6) Run with coverage (terminal)"
    echo "  7) Run with coverage (HTML)"
    echo ""
    echo "Usage: ./run_tests.sh [1-7]"
    echo ""
    read -p "Enter option (1-7): " choice
else
    choice=$1
fi

case $choice in
    1)
        echo "Running all tests..."
        pytest
        ;;
    2)
        echo "Running all tests (verbose)..."
        pytest -v
        ;;
    3)
        echo "Running authentication tests..."
        pytest tests/test_auth_endpoints.py -v
        ;;
    4)
        echo "Running API endpoint tests..."
        pytest tests/test_api_endpoints.py -v
        ;;
    5)
        echo "Running integration tests..."
        pytest tests/test_integration.py -v
        ;;
    6)
        echo "Running tests with coverage report (terminal)..."
        pytest --cov=app --cov=routes --cov=auth --cov-report=term-missing
        ;;
    7)
        echo "Running tests with coverage report (HTML)..."
        pytest --cov=app --cov=routes --cov=auth --cov-report=html
        echo ""
        echo "✓ Coverage report generated in htmlcov/index.html"
        echo "  Open it with: open htmlcov/index.html"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "✓ Test execution completed"
