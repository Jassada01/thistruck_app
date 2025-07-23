# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **ThistruckOn Mobile App** - a Flutter application that appears to be a mobile companion for a truck management system. The app features:
- Firebase integration for push notifications
- User authentication via passcode
- Device tracking and management
- Custom theming system with light/dark modes
- Thai language support with NotoSansThai fonts

## Common Development Commands

### Building and Running
```bash
# Install dependencies
flutter pub get

# Run the app in development mode
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Clean build cache
flutter clean
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Run tests
flutter test
```

## Architecture Overview

### Core Structure
- **main.dart**: Entry point with Firebase initialization and routing setup
- **firebase_options.dart**: Auto-generated Firebase configuration
- **Screen-based architecture** with separate folders for different app sections

### Key Directories

#### `/lib/screen/`
- `splash/` - App initialization and Firebase setup
- `auth/` - Login functionality with passcode authentication
- `dashboard/` - Main app dashboard
- `push_notification/` - Push notification debug/testing screen

#### `/lib/service/`
- `api_service.dart` - HTTP API communication with backend (localhost:127.0.0.1)
- `notification_service.dart` - Firebase Cloud Messaging handling
- `local_storage.dart` - SharedPreferences wrapper
- `activity_tracker.dart` - User activity tracking

#### `/lib/provider/`
- `theme_provider.dart` - State management for app theming using Provider pattern

#### `/lib/theme/`
- `app_theme.dart` - Custom theme system with light/dark modes
- Comprehensive color schemes and design tokens

#### `/lib/config/`
- `font_config.dart` - Font configuration for Thai language support

#### `/lib/widgets/`
- `theme_switcher.dart` - UI component for theme switching

### State Management
- Uses **Provider** pattern for theme management
- SharedPreferences for data persistence
- Local state management in individual screens

### Backend Integration
- API endpoint: `http://127.0.0.1/thistruck/function/mobile/mainFunction.php`
- Function-based API calls (f=5 for login, f=3 for device updates, etc.)
- Device information collection (Android/iOS specific data)
- FCM token management for push notifications

### Firebase Services
- Firebase Core for app initialization
- Firebase Cloud Messaging for push notifications
- Background message handling configured

### Thai Language Support
- Custom NotoSansThai font family with multiple weights (400, 500, 600, 700)
- Thai text rendering throughout the app
- Google Fonts integration as fallback

### Environment Configuration
- Uses flutter_dotenv for environment variables
- .env file loaded as asset for configuration

## Important Notes

### API Structure
The backend uses a function-based API system:
- Function 3: Create/update device info
- Function 5: User login with passcode
- Function 7: Get user devices
- Function 8: Reset passcode
- Function 11: Update last active

### Device Management
The app collects comprehensive device information including:
- Platform (Android/iOS)
- Device model, brand, manufacturer
- OS version and SDK details
- Unique device identifiers
- FCM tokens for push notifications

### Development Environment
- Flutter SDK 3.7.2+
- Uses Material 3 design system
- Supports both Android and iOS platforms
- Local development server at 127.0.0.1

### Testing
Tests are located in `/test/` directory. Use `flutter test` to run the test suite.