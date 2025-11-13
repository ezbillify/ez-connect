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

Copy the development template and provide local credentials (file is git-ignored):

```bash
cp config/environments/.env.development config/environments/.env.development.local
```

Edit `config/environments/.env.development.local` with your Supabase URL, anon key, and any other environment-specific values. Repeat this pattern for staging/production by copying the respective template files.

Run the app with a specific environment by exporting `APP_ENV` or passing it as a dart define:

```bash
APP_ENV=development flutter run -d chrome
# or
flutter run --dart-define=APP_ENV=staging
```

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

Environment files are stored under `config/environments/` and bundled with the app:

```
config/environments/
├── .env.development
├── .env.staging
├── .env.test
└── .env.production
```

Select the active configuration with the `APP_ENV` dart define:

```bash
APP_ENV=staging flutter run -d chrome
# or pass as a flag
flutter run --dart-define=APP_ENV=production
```

Each file contains Supabase credentials for that environment. For secrets, create `.env.<env>.local` files (ignored by git) and surface them through your CI/CD system.

Access variables through the `Env` helper:

```dart
import 'package:app/shared/utils/env.dart';

final supabaseUrl = Env.supabaseUrl;
final anonKey = Env.supabaseAnonKey;
final currentEnvironment = Env.appEnvironment;
```

See [Environment Configuration](docs/ENVIRONMENT_CONFIGURATION.md) for more details.

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

## Testing & Quality Gates

We follow a layered testing approach (unit ➜ widget ➜ integration). See [docs/TESTING_STRATEGY.md](docs/TESTING_STRATEGY.md) for full details.

Common commands:
```bash
# Full suite with Supabase + coverage
./scripts/run_flutter_tests.sh

# Unit tests only
flutter test test/models test/repositories test/features

# Widget tests only
flutter test test/widget_tests
```

Coverage reports are generated automatically under `coverage/` when running the full suite. The CI pipeline uploads `coverage/lcov.info` as an artifact for every pull request.

## Continuous Integration

GitHub Actions (`.github/workflows/flutter_ci.yml`) enforces code quality on every push and pull request:

1. `dart format --set-exit-if-changed` – formatting gate.
2. `flutter analyze` – static analysis and linting.
3. `scripts/bootstrap_supabase_ci.sh` – starts Supabase locally, applies migrations, and seeds test data.
4. `flutter test --coverage` – full unit/widget/integration suite with coverage.
5. Uploads `coverage/lcov.info` and Supabase logs (`supabase-ci.log`) as workflow artifacts.

## Deployment

See the [deployment checklist](docs/deployment/DEPLOYMENT_CHECKLIST.md) for a complete pre-release walkthrough.

### Web
1. `APP_ENV=production ./scripts/build_web.sh`
2. Deploy the contents of `build/web/` to your hosting provider (Vercel, Netlify, Firebase Hosting, etc.).
3. Configure SPA rewrite rules so unknown routes fall back to `index.html`.

### Android
1. Copy `android/key.properties.example` to `android/key.properties` and update it with your keystore credentials.
2. `APP_ENV=production ./scripts/build_android.sh appbundle`
3. Upload the generated `.aab` to Google Play Console and complete the release process.

### iOS
1. Open `ios/Runner.xcworkspace` to verify bundle identifiers and signing teams.
2. `APP_ENV=production ./scripts/build_ios.sh --no-codesign` (remove `--no-codesign` when codesigning for TestFlight/App Store).
3. Upload the resulting `.ipa` via Xcode Organizer or Transporter.

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
# CRM Application

A comprehensive Customer Relationship Management (CRM) application built with Flutter and Supabase, featuring product management, customer tracking, acquisition pipeline, and interaction logging.

## Features

### 1. Product Management
- **List View**: Display all products with active/inactive status
- **Detail View**: View comprehensive product information
- **Create/Edit**: Add new products or update existing ones
- **Active Product Limit**: Maximum of 3 active products enforced at both UI and backend levels
- **Real-time Updates**: Products list updates automatically via Supabase subscriptions

### 2. Customer Management
- **List View**: Browse all customers with search and filter capabilities
- **Search**: Search customers by name, email, or phone
- **Filter**: Filter by product, status, or archived status
- **Detail View**: View complete customer information
- **Create/Edit**: Add new customers or update existing records
- **Soft Deletion**: Archive customers instead of permanent deletion
- **Product Association**: Link customers to products

### 3. Acquisition Pipeline
- **Kanban View**: Visual pipeline with drag-and-drop functionality
- **List View**: Alternative view showing customers grouped by stage
- **Pipeline Stages**:
  - Lead
  - Qualified
  - Proposal
  - Negotiation
  - Closed Won
  - Closed Lost
- **Stage Transitions**: Move customers through stages via drag-and-drop
- **Acquisition Tracking**: Record acquisition source and owner for each customer

### 4. Customer Interaction Logging
- **Add Interactions**: Log customer interactions with details
- **Interaction Types**: Phone, Email, Meeting, Chat, Other
- **Notes**: Record detailed notes for each interaction
- **Follow-ups**: Schedule follow-up dates for future actions
- **Chronological History**: View all interactions in timeline format
- **Real-time Updates**: Interaction list updates automatically

## Architecture

### Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart        # Supabase configuration
│   ├── constants/
│   │   └── database_constants.dart     # Database table names and constants
│   ├── errors/
│   │   └── app_error.dart              # Custom error types
│   └── utils/
│       └── result.dart                 # Result type for error handling
├── models/
│   ├── product.dart                    # Product data model
│   ├── customer.dart                   # Customer data model
│   ├── acquisition_stage.dart          # Acquisition stage model
│   └── customer_interaction.dart       # Interaction model
├── repositories/
│   ├── product_repository.dart         # Product data operations
│   ├── customer_repository.dart        # Customer data operations
│   └── customer_interaction_repository.dart  # Interaction data operations
├── features/
│   ├── products/
│   │   ├── screens/                    # Product screens
│   │   ├── view_models/                # Product view models
│   │   └── widgets/                    # Product widgets
│   ├── customers/
│   │   ├── screens/                    # Customer screens
│   │   ├── view_models/                # Customer view models
│   │   └── widgets/                    # Customer widgets
│   ├── acquisition/
│   │   ├── screens/                    # Pipeline screens
│   │   └── widgets/                    # Pipeline widgets
│   └── interactions/
│       └── screens/                    # Interaction screens
└── main.dart                           # Application entry point

test/
├── models/                             # Model unit tests
├── repositories/                       # Repository unit tests
├── features/                           # View model tests
├── widget_tests/                       # Widget tests
└── golden_tests/                       # Golden/screenshot tests
```

### Design Patterns

- **Repository Pattern**: Abstracts data access from business logic
- **MVVM**: Model-View-ViewModel pattern for UI state management
- **Provider**: State management using the Provider package
- **Result Type**: Functional error handling with Success/Failure types

## Data Models

### Product
```dart
{
  id: String,
  name: String,
  description: String,
  isActive: bool,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### Customer
```dart
{
  id: String,
  name: String,
  email: String?,
  phone: String?,
  productId: String?,
  status: String,
  acquisitionSource: String?,
  owner: String?,
  isArchived: bool,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### CustomerInteraction
```dart
{
  id: String,
  customerId: String,
  type: String,
  channel: InteractionChannel,
  note: String,
  followUpDate: DateTime?,
  createdAt: DateTime
}
```

## Supabase Integration

### Database Schema

Create the following tables in your Supabase database:

#### Products Table
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to enforce max 3 active products
CREATE OR REPLACE FUNCTION check_max_active_products()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_active = true THEN
    IF (SELECT COUNT(*) FROM products WHERE is_active = true AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000')) >= 3 THEN
      RAISE EXCEPTION 'Maximum of 3 active products allowed';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_active_products
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION check_max_active_products();
```

#### Customers Table
```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  product_id UUID REFERENCES products(id),
  status TEXT DEFAULT 'lead',
  acquisition_source TEXT,
  owner TEXT,
  is_archived BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_customers_status ON customers(status);
CREATE INDEX idx_customers_product ON customers(product_id);
CREATE INDEX idx_customers_archived ON customers(is_archived);
```

#### Customer Interactions Table
```sql
CREATE TABLE customer_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  channel TEXT NOT NULL,
  note TEXT NOT NULL,
  follow_up_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_interactions_customer ON customer_interactions(customer_id);
```

### Real-time Configuration

Enable real-time for all tables in Supabase:
1. Go to Database → Replication
2. Enable replication for: `products`, `customers`, `customer_interactions`

### Environment Variables

Set up your Supabase credentials:

```bash
flutter run --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Or update `lib/core/config/supabase_config.dart` with your credentials.

## Offline Support

The application implements offline-aware error handling:

- **Network Error Detection**: Catches `SocketException` and displays appropriate error messages
- **Optimistic Updates**: View models update local state immediately before syncing with backend
- **Error Recovery**: Users can retry failed operations
- **Graceful Degradation**: UI remains functional even when offline (displays cached data)

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test Suites
```bash
# Model tests
flutter test test/models/

# Repository tests
flutter test test/repositories/

# View model tests
flutter test test/features/

# Widget tests
flutter test test/widget_tests/

# Golden tests
flutter test test/golden_tests/
```

### Generate Golden Test Baselines
```bash
flutter test --update-goldens
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Supabase account

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd crm_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Set up Supabase
   - Create a Supabase project
   - Run the database schema scripts
   - Enable real-time replication
   - Copy your project URL and anon key

4. Configure environment
   - Update `lib/core/config/supabase_config.dart` with your credentials
   - Or use `--dart-define` flags when running

5. Run the app
```bash
flutter run
```

## Development Workflow

### Adding a New Feature

1. Create model in `lib/models/`
2. Create repository in `lib/repositories/`
3. Create view model in `lib/features/<feature>/view_models/`
4. Create screens in `lib/features/<feature>/screens/`
5. Create widgets in `lib/features/<feature>/widgets/`
6. Add tests for all components

### Database Migrations

When schema changes are needed:
1. Update SQL scripts in README
2. Run migrations on Supabase
3. Update models to match new schema
4. Update repositories as needed
5. Add migration notes to CHANGELOG

## Best Practices

### Error Handling
- Always use the `Result` type for operations that can fail
- Handle both `Success` and `Failure` cases
- Display user-friendly error messages
- Log errors for debugging

### State Management
- Use `Provider` for dependency injection
- Use `ChangeNotifier` for view models
- Dispose resources properly
- Avoid rebuilding entire widget tree

### Data Synchronization
- Subscribe to Supabase real-time updates
- Implement optimistic updates for better UX
- Handle conflicts gracefully
- Cache data locally when appropriate

### UI/UX
- Show loading indicators for async operations
- Provide feedback for user actions
- Implement pull-to-refresh
- Handle empty states
- Support offline scenarios

## Contributing

1. Create a feature branch
2. Implement changes with tests
3. Update documentation
4. Submit pull request

## License

MIT License - see LICENSE file for details
