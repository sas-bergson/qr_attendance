# 🚀 API Layer Quick Reference

## File Locations

```
frontend/lib/
├── services/
│   ├── api_service.dart              # Core HTTP + JWT
│   ├── auth_service.dart             # Login/profile/auth
│   ├── event_service.dart            # Events CRUD
│   ├── attendance_service.dart       # Attendance marking
│   └── exceptions/
│       └── api_exceptions.dart       # 9 exception types
└── config/
    └── api_constants.dart            # Endpoints + config

frontend/
├── FRONTEND_API_GUIDE.md             # Comprehensive guide
├── API_LAYER_CHECKLIST.md            # Integration steps
└── API_LAYER_SUMMARY.md              # This overview
```

---

## 🔑 Key Classes

### ApiService (Singleton)
```dart
// Initialize in main()
await ApiService().initialize(debugMode: true);

// Use anywhere
final apiService = ApiService();
await apiService.get('/api/v1/endpoint');
await apiService.post('/api/v1/endpoint', body: {...});
await apiService.put('/api/v1/endpoint', body: {...});
await apiService.delete('/api/v1/endpoint');
```

### AuthService (Singleton)
```dart
final authService = AuthService();

await authService.login(email, password);
await authService.register(email, password, name);
await authService.logout();
await authService.getProfile();
bool isAuth = await authService.isAuthenticated();
```

### EventService (Singleton)
```dart
final eventService = EventService();

List events = await eventService.getEvents(limit: 10);
Map event = await eventService.getEvent(eventId);
List attendance = await eventService.getEventAttendance(eventId);
```

### AttendanceService (Singleton)
```dart
final attendanceService = AttendanceService();

await attendanceService.markAttendance(eventId, qrData);
List history = await attendanceService.getUserAttendance();
await attendanceService.validateQrCode(qrData);
```

---

## 🛡️ Exception Types (9)

```dart
try {
  // API call
} on NetworkException catch (e) {
  // No internet, timeout, connection error
} on AuthException catch (e) {
  // Invalid credentials, unauthorized
} on TokenRefreshException catch (e) {
  // Session expired, need login
} on ValidationException catch (e) {
  // 400/422 invalid data
  print(e.errors);  // Map of validation errors
} on ServerException catch (e) {
  // 500+ server error
  print(e.statusCode);  // HTTP status
} on NotFoundException catch (e) {
  // 404 not found
} on ConflictException catch (e) {
  // 409 duplicate resource
} on RateLimitException catch (e) {
  // 429 too many requests
  print(e.retryAfterSeconds);
} on UnknownApiException catch (e) {
  // Other errors
}
```

---

## 📚 Common Patterns

### Pattern 1: Login Flow
```dart
final authService = AuthService();

try {
  await authService.login(email, password);
  // Tokens automatically saved
  navigateToHome();
} on AuthException {
  showError('Invalid email or password');
} on NetworkException {
  showError('Check your internet connection');
}
```

### Pattern 2: Fetch Data with Loading
```dart
bool _isLoading = false;
List _events = [];

Future<void> loadEvents() async {
  _isLoading = true;
  
  try {
    _events = await EventService().getEvents();
  } on ApiException catch (e) {
    showError(e.message);
  } finally {
    _isLoading = false;
    notifyListeners();  // If using Provider
  }
}
```

### Pattern 3: Mark Attendance
```dart
try {
  await AttendanceService().markAttendance(
    eventId: event['id'],
    qrCodeData: scannedQR,
  );
  showSuccess('Attendance marked!');
} on ValidationException catch (e) {
  showError('Invalid QR code: ${e.message}');
} on ApiException catch (e) {
  showError('Error: ${e.message}');
}
```

### Pattern 4: Check Authentication
```dart
if (!await AuthService().isAuthenticated()) {
  navigateToLogin();
  return;
}

// Proceed with authenticated operation
final profile = await AuthService().getProfile();
```

---

## 🔌 Initialization

### main.dart
```dart
import 'services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment
  try {
    await dotenv.load();
  } catch (e) {
    print('No .env file');
  }
  
  // Initialize API Service
  await ApiService().initialize(debugMode: true);
  
  runApp(const QRAttendanceApp());
}
```

---

## 🐛 Debug Logging

### Enable Debug Mode
```dart
await ApiService().initialize(debugMode: true);
```

### Output Example
```
[API Service] 📤 POST /api/v1/auth/login
[API Service]    Body: {"email":"user@example.com","password":"***"}
[API Service] 📥 Status: 200
[API Service]    Body: {"access_token":"eyJ0...","user":{"id":"1","name":"User"}}
[API Service] ✅ Tokens saved
```

---

## 📱 API Endpoints Quick List

### Auth Endpoints
```
POST   /api/v1/auth/login
POST   /api/v1/auth/register
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/profile
POST   /api/v1/auth/verify
```

### Event Endpoints
```
GET    /api/v1/events
GET    /api/v1/events/{id}
POST   /api/v1/events
PUT    /api/v1/events/{id}
DELETE /api/v1/events/{id}
GET    /api/v1/events/{id}/attendance
```

### Attendance Endpoints
```
POST   /api/v1/attendance/mark
GET    /api/v1/attendance
GET    /api/v1/attendance/{id}
```

See `config/api_constants.dart` for complete list.

---

## ✅ Pre-Checklist Before Using

- [ ] `await ApiService().initialize()` called in main()
- [ ] Backend is running at correct URL
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] SharedPreferences available (auto-included)
- [ ] Internet permission set in app config
- [ ] .env file exists (optional, has defaults)

---

## 🎯 Testing Services

### Quick Service Test
```dart
// In a debug screen or main
final eventService = EventService();

try {
  final events = await eventService.getEvents(limit: 5);
  print('✅ Success: ${events.length} events');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 📖 For More Details

- **Full Guide**: `FRONTEND_API_GUIDE.md`
- **Integration Steps**: `API_LAYER_CHECKLIST.md`
- **Code Examples**: Check each service file
- **Backend API**: `../backend/README.md`

---

## 🚀 Next Step

Create **AuthProvider** in `providers/auth_provider.dart` to connect API layer to UI with state management.
