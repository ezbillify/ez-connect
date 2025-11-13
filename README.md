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
