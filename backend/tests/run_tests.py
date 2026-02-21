"""
Example test runner script - demonstrates how to run tests with various configurations
Run this from the backend directory: python tests/run_tests.py
"""
import subprocess
import sys
import os


def run_command(cmd, description):
    """Run a command and print results"""
    print(f"\n{'='*70}")
    print(f"📋 {description}")
    print(f"{'='*70}")
    print(f"$ {cmd}\n")
    
    result = subprocess.run(cmd, shell=True)
    
    if result.returncode != 0:
        print(f"❌ Failed with exit code {result.returncode}")
    else:
        print(f"✓ Completed successfully")
    
    return result.returncode


def main():
    """Run various test scenarios"""
    os.chdir(os.path.dirname(os.path.abspath(__file__)) or '.')
    
    print("\n")
    print("╔" + "="*68 + "╗")
    print("║" + " "*15 + "Flask Attendance System - Test Runner" + " "*15 + "║")
    print("╚" + "="*68 + "╝")
    
    results = {}
    
    # Test 1: Run all tests
    results['all'] = run_command(
        'pytest',
        'Running ALL tests'
    )
    
    # Test 2: Run tests with verbose output
    results['verbose'] = run_command(
        'pytest -v',
        'Running tests with VERBOSE output'
    )
    
    # Test 3: Run authentication tests only
    results['auth'] = run_command(
        'pytest tests/test_auth_endpoints.py -v',
        'Running AUTHENTICATION tests only'
    )
    
    # Test 4: Run API endpoint tests only
    results['api'] = run_command(
        'pytest tests/test_api_endpoints.py -v',
        'Running API ENDPOINT tests only'
    )
    
    # Test 5: Run integration tests only
    results['integration'] = run_command(
        'pytest tests/test_integration.py -v',
        'Running INTEGRATION tests only'
    )
    
    # Test 6: Run tests with coverage
    results['coverage'] = run_command(
        'pytest --cov=app --cov=routes --cov=auth --cov-report=term-missing',
        'Running tests with COVERAGE report'
    )
    
    # Test 7: Run specific test class
    results['test_class'] = run_command(
        'pytest tests/test_auth_endpoints.py::TestAuthLogin -v',
        'Running specific TEST CLASS (TestAuthLogin)'
    )
    
    # Test 8: Run specific test
    results['test_specific'] = run_command(
        'pytest tests/test_auth_endpoints.py::TestAuthLogin::test_login_successful_student -v',
        'Running SPECIFIC test'
    )
    
    # Summary
    print("\n")
    print("╔" + "="*68 + "╗")
    print("║" + " "*25 + "TEST SUMMARY" + " "*31 + "║")
    print("╠" + "="*68 + "╣")
    
    for test_name, returncode in results.items():
        status = "✓ PASS" if returncode == 0 else "✗ FAIL"
        print(f"║ {test_name:20s} {status:45s} ║")
    
    print("╚" + "="*68 + "╝\n")


if __name__ == '__main__':
    main()
