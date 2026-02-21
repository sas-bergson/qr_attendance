# QR Attendance - Flutter Frontend

A Flutter application for the QR Attendance Management System with support for web, mobile (iOS/Android), and desktop platforms.

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── config/
│   │   ├── app_config.dart          # Environment & app configuration
│   │   ├── theme.dart               # App theming & colors
│   │   └── constants.dart           # Constants & validation rules
│   ├── models/
│   │   ├── department.dart
│   │   ├── course.dart
│   │   ├── event.dart
│   │   ├── user.dart
│   │   ├── attendance.dart
│   │   └── index.dart               # Barrel export
│   ├── services/
│   │   ├── api_client.dart          # HTTP client with Dio
│   │   ├── auth_service.dart        # Authentication logic
│   │   ├── department_service.dart
│   │   └── attendance_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart       # State management
│   │   ├── department_provider.dart
│   │   └── attendance_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── departments_screen.dart
│   │   └── attendance_screen.dart
│   ├── widgets/
│   │   ├── department_card.dart
│   │   ├── course_tile.dart
│   │   └── loading_widget.dart
│   └── utils/
│       ├── validators.dart
│       └── logger.dart
├── pubspec.yaml                      # Dependencies
├── .env.example                      # Environment template
└── README.md                          # This file
```

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Environment Configuration

Copy `.env.example` to `.env` and update with your backend URL:

```bash
cp .env.example .env
```

Edit `.env`:
```
API_URL=http://localhost:5000/api/v1
AUTH_URL=http://localhost:5000/api/auth
DEBUG=true
```

### 3. Run the App

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run -d ios
```

**Desktop (Windows/Mac/Linux):**
```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## Dependencies

- **Provider** - State management (simple and scalable)
- **Dio** - HTTP client with interceptors
- **shared_preferences** - Local user data storage
- **hive** - Offline data caching
- **flutter_dotenv** - Environment configuration
- **jwt_decoder** - JWT token parsing
- **mobile_scanner** - QR code scanning (mobile)
- **qr_flutter** - QR code generation

## Architecture

### Service Layer
- Handles all API communication
- Manages authentication tokens
- Implements error handling and retry logic

### Provider (State Management)
- Manages app state (user, departments, courses)
- Handles data loading, success, and error states
- Provides dependency injection

### Screens & Widgets
- Stateless widgets for UI
- Consume providers for data and state
- Handle user interactions

## Features (Roadmap)

- ✅ Phase 1: Project structure & models
- ⏳ Phase 2: API client & services
- ⏳ Phase 3: Login screen & authentication
- ⏳ Phase 4: Dashboard & data display
- ⏳ Phase 5: QR code scanner
- ⏳ Phase 6: Offline support

## Team Guidelines

### Code Style
- Use 2-space indentation
- Follow Dart naming conventions
- Use const constructors where possible
- Add comments for complex logic

### State Management
- Use Provider for app state
- Keep business logic in services
- Use ChangeNotifier for providers
- Avoid setState in StatefulWidgets

### Error Handling
- Always handle network errors
- Show user-friendly error messages
- Log errors for debugging
- Implement retry mechanisms

## Backend Integration

The frontend communicates with the Flask backend at:
- **Data API**: `http://localhost:5000/api/v1/`
- **Auth API**: `http://localhost:5000/api/auth/`

See [backend README](../backend/README.md) for API documentation.

## Testing

```bash
# Run tests
flutter test

# Run specific test
flutter test test/models/user_test.dart
```

## Building for Release

```bash
# Web
flutter build web --release

# APK (Android)
flutter build apk --release

# IPA (iOS)
flutter build ios --release

# Windows
flutter build windows --release
```

## Contributing

1. Create a feature branch (`git checkout -b feature/my-feature`)
2. Commit your changes (`git commit -am 'Add my feature'`)
3. Push to the branch (`git push origin feature/my-feature`)
4. Open a Pull Request

## Support

For issues or questions, contact the development team or create an issue in the repository.
