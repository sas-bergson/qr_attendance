/// API Service Layer Documentation
///
/// This is the comprehensive guide for the API Service Layer implementation.
/// 
/// ## Overview
///
/// The API Service Layer provides a clean, type-safe abstraction over HTTP
/// communication with the Flask backend. It handles:
///
/// - HTTP request/response management
/// - JWT token storage and automatic refresh
/// - Error handling and custom exceptions
/// - Request/response logging
/// - Retry logic on token expiration
///
/// ## Architecture
///
/// ```
/// Widget Layer
///    ↓
/// Provider Layer (State Management)
///    ↓
/// Service Layer (API Service, Auth Service, Event Service, etc.)
///    ↓
/// API Service (HTTP Client + Token Management)
///    ↓
/// Backend API (Flask)
/// ```
///
/// ## Components
///
/// ### 1. ApiService (services/api_service.dart)
/// Core HTTP client handling:
/// - Base URL management (auto-detected from AppConfig)
/// - JWT token handling (storage, refresh, validation)
/// - Automatic token refresh on 401
/// - Comprehensive error handling
/// - Debug logging
///
/// ### 2. Exception Classes (services/exceptions/api_exceptions.dart)
/// Custom exception hierarchy:
/// - NetworkException: No internet, timeout, socket errors
/// - AuthException: Invalid credentials, unauthorized access
/// - TokenRefreshException: Token refresh failures
/// - ValidationException: 400/422 validation errors
/// - ServerException: 500+ server errors
/// - NotFoundException: 404 errors
/// - ConflictException: 409 duplicate resources
/// - RateLimitException: 429 too many requests
/// - UnknownApiException: Unexpected errors
///
/// ### 3. Service Classes
/// Domain-specific API operations:
/// - AuthService: Login, register, profile management
/// - EventService: Event CRUD and querying
/// - AttendanceService: Attendance marking, history, statistics
///
/// ### 4. Constants (config/api_constants.dart)
/// Centralized configuration:
/// - Base URL
/// - All API endpoints
/// - HTTP timeout values
/// - Storage key names
///
/// ## Usage Examples
///
/// ### Initialization (in main.dart)
///
/// ```dart
/// import 'package:qr_attendance/services/api_service.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize API Service
///   await ApiService().initialize(debugMode: true);
///   
///   runApp(const QRAttendanceApp());
/// }
/// ```
///
/// ### Login (Use AuthService)
///
/// ```dart
/// final authService = AuthService();
/// 
/// try {
///   final result = await authService.login(
///     email: 'user@example.com',
///     password: 'password123',
///   );
///   
///   print('Login successful!');
///   print('User: ${result['user']['name']}');
///   // Tokens are automatically saved
/// } on AuthException catch (e) {
///   print('Login failed: ${e.message}');
/// }
/// ```
///
/// ### Fetch Events (Use EventService)
///
/// ```dart
/// final eventService = EventService();
/// 
/// try {
///   final events = await eventService.getEvents(limit: 10);
///   print('Found ${events.length} events');
/// } on ApiException catch (e) {
///   print('Error: ${e.message}');
/// }
/// ```
///
/// ### Mark Attendance (Use AttendanceService)
///
/// ```dart
/// final attendanceService = AttendanceService();
/// 
/// try {
///   final result = await attendanceService.markAttendance(
///     eventId: '12345',
///     qrCodeData: 'scanned_qr_data',
///   );
///   print('Attendance marked!');
/// } on ApiException catch (e) {
///   print('Error: ${e.message}');
/// }
/// ```
///
/// ### Direct API Calls (Advanced)
///
/// ```dart
/// final apiService = ApiService();
/// 
/// // GET request
/// final user = await apiService.get('/api/v1/auth/profile');
/// 
/// // POST request
/// final result = await apiService.post(
///   '/api/v1/events',
///   body: {
///     'title': 'New Event',
///     'description': 'Event description',
///   },
/// );
/// 
/// // PUT request
/// final updated = await apiService.put(
///   '/api/v1/users/123',
///   body: {'name': 'New Name'},
/// );
/// 
/// // DELETE request
/// await apiService.delete('/api/v1/events/123');
/// ```
///
/// ## Error Handling Strategy
///
/// The API Service layer provides structured error handling:
///
/// ```dart
/// try {
///   final events = await eventService.getEvents();
/// } on NetworkException catch (e) {
///   // No internet, timeout, socket error
///   showSnackBar('Check your internet connection');
/// } on AuthException catch (e) {
///   // Invalid credentials or unauthorized
///   navigateToLogin();
/// } on TokenRefreshException catch (e) {
///   // Session expired, need to login again
///   showSnackBar('Session expired. Please login again.');
///   navigateToLogin();
/// } on ValidationException catch (e) {
///   // Invalid request data (400/422)
///   showSnackBar('Please check your input: ${e.message}');
/// } on ServerException catch (e) {
///   // Server error (500+)
///   showSnackBar('Server error. Please try again later.');
/// } on ApiException catch (e) {
///   // Generic API error
///   showSnackBar('Error: ${e.message}');
/// }
/// ```
///
/// ## Token Management
///
/// ### Automatic Token Refresh
///
/// When a request returns 401 (Unauthorized):
/// 1. ApiService automatically tries to refresh the token
/// 2. If refresh succeeds, the original request is retried
/// 3. If refresh fails, TokenRefreshException is thrown
/// 4. User is prompted to login again
///
/// ### Manual Token Check
///
/// ```dart
/// final apiService = ApiService();
/// 
/// // Check if user is authenticated
/// if (apiService.isAuthenticated()) {
///   // User has valid token
/// } else {
///   // Token invalid or expired, need to login
///   navigateToLogin();
/// }
/// ```
///
/// ### Token Verification
///
/// ```dart
/// final authService = AuthService();
/// 
/// final isValid = await authService.verifyToken();
/// if (!isValid) {
///   // Token invalid
///   navigateToLogin();
/// }
/// ```
///
/// ### Manual Logout
///
/// ```dart
/// final authService = AuthService();
/// 
/// await authService.logout();
/// // Tokens are cleared, user is logged out
/// ```
///
/// ## With Provider for State Management
///
/// The API Services work seamlessly with Provider for state management:
///
/// ```dart
/// // services/auth_provider.dart
/// class AuthProvider with ChangeNotifier {
///   final AuthService _authService = AuthService();
///   bool _isLoading = false;
///   
///   Future<void> login(String email, String password) async {
///     _isLoading = true;
///     notifyListeners();
///     
///     try {
///       await _authService.login(
///         email: email,
///         password: password,
///       );
///       // Success - widgets will rebuild
///     } on AuthException catch (e) {
///       // Show error
///       _errorMessage = e.message;
///     } finally {
///       _isLoading = false;
///       notifyListeners();
///     }
///   }
/// }
/// ```
///
/// ## Debug Mode
///
/// Enable debug logging to see detailed API operations:
///
/// ```dart
/// // In main.dart
/// await ApiService().initialize(debugMode: true);
/// 
/// // Output example:
/// // [API Service] 📤 GET /api/v1/events
/// // [API Service] 📥 Status: 200
/// // [API Service] 📥 Body: [{"id":"1","title":"Event 1"}]
/// ```
///
/// ## Best Practices
///
/// 1. **Always use specific service classes** (AuthService, EventService, etc.)
///    - Better code organization
///    - Clearer intent
///    - Easier to test
///
/// 2. **Handle exceptions properly**
///    - Catch specific exceptions (don't use generic catch)
///    - Show user-friendly error messages
///    - Log detailed errors for debugging
///
/// 3. **Check authentication before API calls**
///    ```dart
///    if (!apiService.isAuthenticated()) {
///      navigateToLogin();
///      return;
///    }
///    ```
///
/// 4. **Use try-catch-finally**
///    ```dart
///    try {
///      _isLoading = true;
///      final result = await service.operation();
///    } catch (e) {
///      handleError(e);
///    } finally {
///      _isLoading = false;
///    }
///    ```
///
/// 5. **Leverage Dart's strong typing**
///    - Return types are clear
///    - IDE autocomplete helps
///    - Fewer runtime errors
///
/// ## Troubleshooting
///
/// ### "401 Unauthorized" errors
/// - Check if token is valid: `apiService.isAuthenticated()`
/// - Try logging in again: `authService.login(...)`
/// - Check token expiration in ApiService logs
///
/// ### "Network error" messages
/// - Check device internet connection
/// - Verify backend URL in ApiConstants
/// - Check network requests in browser DevTools
///
/// ### "Invalid request" errors (400/422)
/// - Check request body format
/// - Verify all required fields are present
/// - Check field types match backend expectations
///
/// ### Tokens not persisting after app restart
/// - Ensure `ApiService().initialize()` is called in main()
/// - Check SharedPreferences permissions
/// - Verify tokens are being saved correctly
///
/// ## File Structure
///
/// ```
/// lib/
/// ├── services/
/// │   ├── api_service.dart              # Core HTTP client
/// │   ├── auth_service.dart             # Authentication
/// │   ├── event_service.dart            # Event operations
/// │   ├── attendance_service.dart       # Attendance operations
/// │   └── exceptions/
/// │       └── api_exceptions.dart       # Exception classes
/// ├── config/
/// │   ├── app_config.dart               # App configuration
/// │   ├── api_constants.dart            # API endpoints
/// │   ├── theme.dart                    # Theme configuration
/// │   └── constants.dart                # General constants
/// ├── providers/
/// │   ├── auth_provider.dart            # Auth state management
/// │   ├── event_provider.dart           # Event state management
/// │   └── attendance_provider.dart      # Attendance state management
/// ├── models/
/// │   ├── user.dart
/// │   ├── event.dart
/// │   ├── attendance.dart
/// │   └── ...
/// ├── screens/
/// │   ├── login_screen.dart
/// │   ├── events_list_screen.dart
/// │   ├── qr_scanner_screen.dart
/// │   └── ...
/// └── main.dart
/// ```
///
/// ## Next Steps
///
/// 1. ✅ API Service Layer (this implementation)
/// 2. ⏳ Create Providers (state management layer)
/// 3. ⏳ Create Screens (UI layer)
/// 4. ⏳ Wire everything together
/// 5. ⏳ Add integration tests
///
