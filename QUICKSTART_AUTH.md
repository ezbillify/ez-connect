# Authentication Module - Quick Start Guide

## What's Included

This implementation provides a complete authentication system with:

✅ Email/password authentication  
✅ Passwordless (magic link) authentication  
✅ Password reset functionality  
✅ User profile and role management  
✅ Session management with auto-refresh  
✅ Protected routes and navigation guards  
✅ Role-based access control ready  
✅ Comprehensive error handling  
✅ Unit and widget tests  

## File Structure

```
lib/
├── data/
│   ├── datasources/
│   │   └── supabase_auth_datasource.dart     # Supabase integration
│   └── repositories/
│       └── auth_repository_impl.dart         # Auth logic implementation
├── domain/
│   ├── models/
│   │   ├── auth_state.dart                   # Auth state model
│   │   └── user.dart                         # User model (updated with role)
│   └── repositories/
│       └── auth_repository.dart              # Auth repository interface
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart                # Riverpod auth state management
    │   └── router_provider.dart              # Router with guards (updated)
    └── screens/
        ├── auth/
        │   ├── login_screen.dart             # Login form
        │   ├── signup_screen.dart            # Signup form with invite support
        │   ├── forgot_password_screen.dart   # Password reset
        │   └── magic_link_screen.dart        # Passwordless login
        └── settings/
            └── settings_screen.dart          # User profile & sign out

test/
├── auth/
│   ├── auth_view_model_test.dart            # Auth state management tests
│   └── login_screen_test.dart               # UI tests for login
└── routing/
    └── routing_guards_test.dart             # Navigation guard tests

docs/
└── AUTHENTICATION.md                         # Comprehensive documentation
```

## Getting Started (5 minutes)

### 1. Set Up Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and add your Supabase credentials:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_ENVIRONMENT=development
```

### 2. Create Supabase Tables

Run these SQL commands in your Supabase project:

**Profiles table:**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE,
  name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
```

**Invitations table (optional, for invite-only signup):**
```sql
CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can validate codes" ON invitations
  FOR SELECT USING (NOT used);
```

### 3. Run Tests

```bash
flutter test test/auth/
flutter test test/routing/
```

### 4. Test the App

```bash
flutter run
```

Navigate to `http://localhost:3000` for web, or use your mobile device.

## Key Features

### 🔐 Authentication Flows

1. **Email/Password**
   - Sign in at `/auth/login`
   - Sign up at `/auth/signup`
   - Password reset at `/auth/forgot-password`

2. **Passwordless**
   - Magic link sign in at `/auth/magic-link`
   - No password required

3. **Invite-Only Signup** (Optional)
   - Enable by requiring `invitationCode` in signup
   - Use `invitations` table to manage codes

### 🛡️ Protected Routes

- `/dashboard` - Requires authentication
- `/crm` - Requires authentication
- `/ticketing` - Requires authentication
- `/settings` - Requires authentication

Unauthenticated users are automatically redirected to `/auth/login`

### 👤 User Profile

Access user information anywhere in the app:

```dart
final currentUser = ref.watch(currentUserProvider);      // User object
final userRole = ref.watch(currentUserRoleProvider);     // User role
final isAuthenticated = ref.watch(isAuthenticatedProvider);
final isLoading = ref.watch(authLoadingProvider);
final error = ref.watch(authErrorProvider);
```

### 🔄 Sign Out

```dart
await ref.read(authProvider.notifier).signOut();
context.go('/auth/login');
```

## State Management

All auth state is managed via Riverpod:

```dart
class AuthState {
  final AuthStatus status;     // initial, loading, authenticated, unauthenticated, error
  final User? user;            // Current user object
  final String? error;         // Error message if any
  final String? userRole;      // User role from profiles
}
```

## Customization

### Add More Auth Methods

Add to `auth_provider.dart`:
```dart
Future<void> signInWithGoogle() async {
  // Implementation
}
```

### Add Role-Based Restrictions

Update `router_provider.dart` redirect logic:
```dart
if (state.uri.path == '/admin' && userRole != 'admin') {
  return '/dashboard';
}
```

### Customize Auth UI

Edit screens in `presentation/screens/auth/`:
- Change colors, fonts, layout
- Add new fields to forms
- Customize error messages

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "SUPABASE_URL is null" | Check `.env` file exists and is loaded |
| "Invalid redirect URI" | Add domain to Supabase URL Configuration |
| "Sign up failed" | Password too short (min 6 chars) or email taken |
| "Tests fail" | Run `flutter pub get` first |

## Next Steps

1. Read [AUTHENTICATION.md](docs/AUTHENTICATION.md) for detailed setup
2. Configure OAuth providers (Google, GitHub, etc.)
3. Customize branding and UI
4. Set up email templates in Supabase
5. Implement additional features as needed

## Support Resources

- 📚 [Supabase Documentation](https://supabase.com/docs)
- 🎯 [Flutter Documentation](https://flutter.dev)
- 🎪 [Riverpod Documentation](https://riverpod.dev)
- 🧭 [GoRouter Documentation](https://pub.dev/packages/go_router)
