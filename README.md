# App - Flutter Multi-Platform Application

A modern Flutter application configured for web, iOS, and Android targets with a clean architecture, state management via Riverpod, and integrated Supabase backend support.

## Features

- **Multi-Platform Support**: Runs seamlessly on Web, iOS, and Android
- **Clean Architecture**: Organized into presentation, domain, and data layers
- **State Management**: Riverpod for reactive state management
- **Routing**: GoRouter for declarative navigation
- **Backend Integration**: Supabase for authentication, data management, and secure external APIs
- **Environment Configuration**: Secure environment variable management
- **Modern UI**: Google Fonts, responsive design helpers, and customizable themes
- **Form Handling**: Reactive Forms for complex form management
- **Module-Based Structure**: Placeholder modules for Dashboard, CRM, Ticketing, and Settings

## Prerequisites

### System Requirements
- **Flutter SDK**: Version 3.2.3 or higher
- **Dart SDK**: Version 3.2.3 or higher (included with Flutter)
- **Node.js**: For web platform (optional but recommended)

### Platform-Specific Requirements

#### macOS (for iOS development)
- **Xcode**: 14.0 or higher
- **CocoaPods**: Latest version
- **iOS Deployment Target**: iOS 11.0 or higher

#### Linux/Windows (for Android development)
- **Android SDK**: API level 21 or higher
- **Android NDK**: Latest version
- **Java**: JDK 11 or higher

#### Web
- Any modern web browser with WebGL support

## Installation

### 1. Set Up Flutter

**On macOS/Linux:**
```bash
# Download and install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"
flutter doctor
```

**On Windows:**
Download from https://flutter.dev/docs/get-started/install/windows

### 2. Clone and Configure the Repository

```bash
# Clone the repository
git clone <repository-url>
cd app

# Get Flutter dependencies
flutter pub get
```

### 3. Environment Configuration

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_ENVIRONMENT=development
```

**Note**: The `.env` file is added to `.gitignore` and should never be committed to version control.

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── presentation/             # UI layer
│   ├── screens/             # Screen implementations
│   │   ├── home/
│   │   ├── dashboard/
│   │   ├── crm/
│   │   ├── ticketing/
│   │   └── settings/
│   ├── widgets/             # Reusable widgets
│   └── providers/           # Riverpod providers (routing, app state)
├── domain/                   # Business logic layer
│   ├── models/              # Data models/entities
│   ├── repositories/        # Repository interfaces
│   └── use_cases/           # Use case implementations
├── data/                     # Data access layer
│   ├── sources/             # API/local data sources
│   └── repositories/        # Repository implementations
└── shared/                   # Shared resources
    ├── theme/               # Theme configuration
    ├── utils/               # Utilities (env, extensions, etc.)
    ├── widgets/             # Shared widgets
    └── helpers/             # Responsive design helpers
```

## Running the Application

### Web

**Development Mode:**
```bash
flutter run -d chrome
```

**Build for Production:**
```bash
flutter build web --release
# Output: build/web/
```

**Serve Production Build:**
```bash
# Using Python 3
python -m http.server 8000 --directory build/web

# Using Node.js
npx serve -s build/web
```

Then navigate to `http://localhost:8000`

### Android

**Prerequisites:**
- Android emulator running or device connected
- Run `flutter doctor -v` to verify setup

**Development Mode:**
```bash
flutter run
# or
flutter run -d <device-id>
```

**List Available Devices:**
```bash
flutter devices
```

**Build APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Build AAB (Google Play Bundle):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

**Prerequisites:**
- macOS with Xcode installed
- iOS simulator running or device connected

**Development Mode:**
```bash
flutter run -d <simulator-id>
```

**List Available Simulators:**
```bash
xcrun simctl list devices available
```

**Build IPA:**
```bash
flutter build ipa --release
# Output: build/ios/ipa/app.ipa
```

**Build for App Store:**
```bash
flutter build ipa --release --export-method=app-store
```

## Development Workflow

### Code Generation

Some packages require code generation (e.g., Riverpod, reactive_forms):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For watching changes during development:
```bash
flutter pub run build_runner watch
```

### Hot Reload

During development, hot reload is automatically available:
```bash
flutter run
# Press 'r' in terminal to hot reload
# Press 'R' to hot restart
```

### Code Style and Analysis

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run linting
flutter analyze --no-fatal-infos
```

## Configuration

### Theme Configuration

Modify `lib/shared/theme/app_theme.dart` to customize:
- Colors
- Typography
- Component styles
- Dark/Light theme variants

### Routing Configuration

Routes are defined in `lib/presentation/providers/router_provider.dart`:

```dart
GoRoute(
  path: '/your-route',
  builder: (context, state) => YourScreen(),
),
```

### Environment-Specific Configuration

Use the `Env` class to access environment variables:

```dart
import 'package:app/shared/utils/env.dart';

final url = Env.supabaseUrl;
final anonKey = Env.supabaseAnonKey;
```

## Supabase Integration

### Initialization

Update `lib/main.dart` to initialize Supabase:

```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

### Usage Example

```dart
final response = await Supabase.instance.client
    .from('table_name')
    .select()
    .execute();
```

## State Management

This project uses **Riverpod** for state management. Create providers in `lib/presentation/providers/`:

```dart
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}
```

Use in widgets:
```dart
final count = ref.watch(counterProvider);
```

## Modules

### Dashboard Module
Location: `lib/presentation/screens/dashboard/`
- Key metrics and statistics
- Quick actions
- System overview

### CRM Module
Location: `lib/presentation/screens/crm/`
- Customer management
- Contact details
- Communication history

### Ticketing Module
Location: `lib/presentation/screens/ticketing/`
- Support ticket management
- Issue tracking
- Resolution workflow

### Settings Module
Location: `lib/presentation/screens/settings/`
- User preferences
- App configuration
- Account management

## Troubleshooting

### Build Issues

**Web build fails:**
```bash
flutter clean
rm -rf .dart_tool pubspec.lock
flutter pub get
flutter build web --release
```

**Dependency conflicts:**
```bash
flutter pub get --offline
flutter pub upgrade --major-versions
flutter clean
```

### Platform-Specific Issues

**iOS:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
flutter run
```

**Android:**
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### Hot Reload Not Working

```bash
# Full restart
flutter run
# Press R in terminal to hot restart
```

## Performance Optimization

### Web
- Built-in tree-shaking reduces icon fonts by ~99%
- Enable production mode for optimal performance
- Consider pre-rendering for static content

### Mobile
- Use `flutter build` with `--release` flag
- Profile with DevTools:
  ```bash
  flutter run --profile
  ```

## Testing

Run tests with:
```bash
flutter test
```

## Deployment

### Web
1. Build: `flutter build web --release`
2. Deploy the `build/web/` directory to your hosting provider
3. Recommended hosts: Firebase Hosting, Vercel, Netlify

### Android
- Generate signing key
- Use Google Play Console for release management
- Follow Play Store guidelines

### iOS
- Create App Store Connect account
- Configure certificates and provisioning profiles
- Use TestFlight for beta testing

## External Integrations

The application supports secure token-based integration for external systems to create and manage tickets programmatically.

**For Developers:**
- See [External Integrations Guide](docs/EXTERNAL_INTEGRATIONS.md) for setup and deployment
- Follow the [Integration Setup Guide](INTEGRATION_SETUP.md) for a step-by-step walkthrough
- See [API Integration Reference](docs/API_INTEGRATION.md) for API documentation
- Check [examples/](examples/) for client code samples

**For Administrators:**
- Navigate to Settings → Integration Tokens to manage API tokens
- Issue, regenerate, disable, and monitor integration tokens
- View detailed usage logs and statistics

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Community](https://flutter.dev/community)

## Contributing

1. Create a new feature branch: `git checkout -b feature/your-feature`
2. Make your changes and commit: `git commit -am 'Add new feature'`
3. Push to the branch: `git push origin feature/your-feature`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or feature requests, please create an issue in the repository or contact the development team.
