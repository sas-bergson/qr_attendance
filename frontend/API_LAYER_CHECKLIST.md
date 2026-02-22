# Frontend API Layer - Integration Checklist ✅

## Phase 1: API Service Layer (COMPLETED ✅)

### Core Components Created:
- ✅ `services/api_service.dart` - HTTP client with JWT management
- ✅ `services/auth_service.dart` - Authentication operations
- ✅ `services/event_service.dart` - Event operations
- ✅ `services/attendance_service.dart` - Attendance operations
- ✅ `services/exceptions/api_exceptions.dart` - Error handling
- ✅ `config/api_constants.dart` - API endpoints & configuration
- ✅ `FRONTEND_API_GUIDE.md` - Comprehensive documentation

### Key Features Implemented:
- ✅ JWT token storage (SharedPreferences)
- ✅ Automatic token refresh on 401
- ✅ Comprehensive error handling (9 exception types)
- ✅ Request/response logging (debug mode)
- ✅ Retry logic for failed requests
- ✅ Base URL auto-detection from AppConfig
- ✅ Singleton pattern for services
- ✅ Timeout handling (30 seconds)
- ✅ Proper header management
- ✅ Query parameter building

### Services Available:

#### AuthService Methods:
- `login(email, password)` - User login with JWT tokens
- `register(email, password, name, departmentId)` - New user registration
- `logout()` - Clear tokens and logout
- `getProfile()` - Get current user profile
- `verifyToken()` - Check if token still valid
- `isAuthenticated()` - Check authentication status
- `updateProfile(userId, name, email, departmentId)` - Update user info
- `changePassword(oldPassword, newPassword)` - Change user password
- `requestPasswordReset(email)` - Request password reset
- `resetPassword(token, newPassword)` - Complete password reset
- `getUserById(userId)` - Get specific user details

#### EventService Methods:
- `getEvents(limit, offset, status, departmentId)` - List all events
- `getEvent(eventId)` - Get event details
- `createEvent(...)` - Create new event (admin)
- `updateEvent(eventId, ...)` - Update event (admin)
- `deleteEvent(eventId)` - Delete event (admin)
- `getEventAttendance(eventId)` - Get event attendance records
- `searchEvents(query)` - Search events by title/description
- `getUpcomingEvents(limit)` - Get future events
- `getEventsByDepartment(departmentId)` - Filter by department
- `getEventStatistics(eventId)` - Get attendance statistics
- `generateQrForEvent(eventId)` - Generate QR code

#### AttendanceService Methods:
- `markAttendance(eventId, qrCodeData)` - Mark attendance via QR
- `validateQrCode(qrCodeData)` - Validate QR before marking
- `getUserAttendance(limit, offset, status)` - Get user's records
- `getAttendanceRecord(attendanceId)` - Get specific record
- `getUserAttendanceById(userId)` - Get user's attendance (admin)
- `getTodayAttendance()` - Get today's attendance
- `getAttendanceByDateRange(startDate, endDate)` - Filter by date
- `getAttendanceStatistics(userId, eventId)` - Get statistics
- `exportAttendance(eventId, format)` - Export as CSV/JSON/XLSX
- `bulkMarkAttendance(eventId, userIds)` - Mark multiple users (admin)
- `generateQrCode(eventId)` - Generate QR code

---

## Phase 2: State Management Layer (NEXT) ⏳

### Providers to Create:

1. **AuthProvider** (providers/auth_provider.dart)
   - Login/logout state
   - User profile data
   - Authentication status
   - Error messages
   - Loading state
   
2. **EventProvider** (providers/event_provider.dart)
   - Events list (with pagination)
   - Filters (department, date, status)
   - Selected event details
   - Loading/error states
   
3. **AttendanceProvider** (providers/attendance_provider.dart)
   - Mark attendance state
   - Attendance history
   - Statistics
   - QR validation status

### Architecture Pattern:
```
Widget (UI)
    ↓
Provider (ChangeNotifier)
    ↓
Service (Business Logic)
    ↓
API Service (HTTP)
    ↓
Backend
```

---

## Phase 3: Screen Implementation (LATER) ⏳

Priority order:

1. **LoginScreen**
   - Email/password form
   - Form validation
   - Error display
   - Success navigation

2. **EventsListScreen**
   - FutureBuilder with EventProvider
   - Event list (ListView/GridView)
   - Filters (department, date)
   - Pull-to-refresh
   - Navigation on tap

3. **QRScannerScreen**
   - QR camera integration
   - Real-time scanning
   - Validation feedback
   - Mark attendance
   - Success confirmation

4. **AttendanceHistoryScreen**
   - User's attendance records
   - Filter by date/event
   - Pagination
   - Export option

5. **SettingsScreen**
   - User profile display
   - Logout button
   - Theme toggle

---

## Integration Steps

### Step 1: Update main.dart
```dart
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API Service
  await ApiService().initialize(debugMode: true);
  
  // Load environment
  try {
    await dotenv.load();
  } catch (e) {
    print('Note: .env file not loaded');
  }
  
  runApp(const QRAttendanceApp());
}
```

### Step 2: Test API Layer
```dart
// Quick test in a debug screen
final authService = AuthService();
final result = await authService.login(
  email: 'test@example.com',
  password: 'password123',
);
print(result); // Should show: {access_token, refresh_token, user}
```

### Step 3: Create First Provider
Create `providers/auth_provider.dart` with ChangeNotifier wrapping AuthService

### Step 4: Create First Screen
Create `screens/login_screen.dart` using AuthProvider

### Step 5: Wire Everything Together
Connect screens → providers → services → API layer

---

## Testing Checklist

### Manual Tests:
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Token refresh on 401
- [ ] Logout clears tokens
- [ ] Fetch events list
- [ ] Get event details
- [ ] Mark attendance via QR
- [ ] Get attendance history
- [ ] Network error handling
- [ ] Token expiration handling

### Debug Logging:
Enable in main.dart:
```dart
await ApiService().initialize(debugMode: true);
```

Shows:
```
[API Service] 📤 POST /api/v1/auth/login
[API Service] 📥 Status: 200
[API Service] 📥 Body: {...response...}
```

---

## Documentation References

- **API Guide**: `FRONTEND_API_GUIDE.md` (comprehensive with examples)
- **API Constants**: `config/api_constants.dart` (all endpoints)
- **Exception Classes**: `services/exceptions/api_exceptions.dart` (error types)
- **Backend API**: `../backend/README.md` (backend documentation)
- **Backend Routes**: `../backend/routes.py` (available endpoints)

---

## Dependencies (Already in pubspec.yaml)

✅ `http: ^1.1.0` - HTTP client
✅ `provider: ^6.0.0` - State management
✅ `shared_preferences: ^2.2.0` - Token storage
✅ `jwt_decoder: ^2.0.1` - JWT parsing
✅ `flutter_dotenv: ^5.1.0` - Environment variables
✅ `dio: ^5.3.0` - Alternative HTTP client (optional)
✅ `mobile_scanner: ^3.4.0` - QR scanning
✅ `qr_flutter: ^4.0.0` - QR generation

---

## Next Immediate Task

**Create AuthProvider** (providers/auth_provider.dart):
- Wrap AuthService with ChangeNotifier
- Manage login/logout state
- Handle loading/error states
- Store user profile data
- Ready for UI consumption

This will be the bridge between API layer and UI screens.

---

## Summary

| Layer                | Status | Files            |
| -------------------- | ------ | ---------------- |
| **API Service**      | ✅ DONE | 6 files created  |
| **State Management** | ⏳ TODO | Need 3 providers |
| **Screens**          | ⏳ TODO | Need 5 screens   |
| **Integration**      | ⏳ TODO | Wire everything  |

**Total API Endpoints Supported**: 30+
**Exception Types**: 9
**Service Classes**: 3
**Debug Capabilities**: Full logging & error details

Ready for Provider layer implementation! 🚀
