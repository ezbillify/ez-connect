# Authentication Module Documentation

This document provides a comprehensive guide to configuring and using the authentication module in this Flutter application.

## Overview

The authentication module integrates Supabase authentication with Flutter using Riverpod for state management. It provides:

- Email/password sign-in and sign-up
- Passwordless authentication (magic links)
- Password reset functionality
- Session management and auto-refresh
- Role-based access control
- User profile caching
- Secure token storage

## Prerequisites

- Supabase project ([Create one here](https://supabase.com))
- Flutter 3.x environment
- An understanding of async/await in Dart

## Setup Instructions

### 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up
2. Create a new project
3. Wait for the project to initialize
4. Go to **Settings > API** to find your credentials

### 2. Configure Environment Variables

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your Supabase credentials to `.env`:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   APP_ENVIRONMENT=development
   ```

   - `SUPABASE_URL`: Found in your Supabase project settings under API
   - `SUPABASE_ANON_KEY`: Found in your Supabase project settings under API

3. **Important**: Add `.env` to `.gitignore` to avoid committing secrets:
   ```bash
   echo ".env" >> .gitignore
   ```

### 3. Set Up Supabase Tables

#### Users/Profiles Table

Create a `profiles` table in Supabase:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE
  USING (auth.uid() = id);
```

#### User Invitations Table

The application now uses an enhanced `user_invitations` table that supports role-based invitations and expiration:

```sql
CREATE TABLE user_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  role user_role DEFAULT 'agent' NOT NULL,
  invited_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
```

**Invitation Features:**
- **Role Assignment**: Invitations can specify the role (admin, agent, customer, guest)
- **Expiration**: Invitations automatically expire after a set time
- **Status Tracking**: pending, accepted, expired, cancelled
- **Audit Trail**: Tracks who created the invitation and when it was used

**Helper Functions:**
- `generate_invitation_code()`: Creates a unique invitation code
- `create_invitation(email, role, expires_in_days)`: Creates a new invitation
- `accept_invitation(code)`: Validates and accepts an invitation
- `expire_old_invitations()`: Automatically expires old invitations

### 4. Configure Authentication Providers

#### Email/Password Authentication

This is enabled by default in Supabase. No additional configuration needed.

#### Magic Link (Passwordless)

To enable magic link authentication:

1. In Supabase Dashboard, go to **Authentication > Providers**
2. Enable "Email" provider if not already enabled
3. Configure redirect URL: `io.supabase.flutter://callback`

#### Additional Providers (Optional)

You can configure OAuth providers like Google, GitHub, etc.:

1. Go to **Authentication > Providers** in Supabase Dashboard
2. Select your desired provider
3. Add your OAuth credentials
4. Update the app to handle the provider (see "Using OAuth" section below)

### 5. Handle Authentication Callbacks

#### iOS Configuration

Edit `ios/Runner/Info.plist` and add:

```xml
<dict>
  ...
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>io.supabase.flutter</string>
      </array>
    </dict>
  </array>
  ...
</dict>
```

#### Android Configuration

Edit `android/app/build.gradle` and ensure:

```gradle
defaultConfig {
    ...
    minSdkVersion 21
}
```

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<activity>
    ...
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="io.supabase.flutter"
            android:host="callback" />
    </intent-filter>
</activity>
```

#### Web Configuration

For web, ensure your Supabase project is configured to allow your domain:

1. In Supabase Dashboard, go to **Authentication > URL Configuration**
2. Add your production domain to "Allowed Redirect URLs"

## Usage Guide

### Authentication State Management

The authentication state is managed by Riverpod. Access it using:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/presentation/providers/auth_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userRole = ref.watch(currentUserRoleProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    
    return Column(
      children: [
        if (isLoading)
          const CircularProgressIndicator()
        else if (currentUser != null)
          Text('Logged in as: ${currentUser.name}')
        else
          const Text('Not logged in'),
        if (userRole != null)
          Text('Role: $userRole'),
        if (error != null)
          Text('Error: $error'),
      ],
    );
  }
}
```

### Sign Up

```dart
final notifier = ref.read(authProvider.notifier);

try {
  await notifier.signUpWithEmailAndPassword(
    email: 'user@example.com',
    password: 'securePassword123',
    name: 'John Doe',
    invitationCode: 'ABC123', // Optional, only if invite-required
  );
} catch (e) {
  print('Sign up failed: $e');
}
```

### Sign In

```dart
final notifier = ref.read(authProvider.notifier);

try {
  await notifier.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  // Navigate to home screen
  context.go('/dashboard');
} catch (e) {
  print('Sign in failed: $e');
}
```

### Magic Link (Passwordless)

```dart
final notifier = ref.read(authProvider.notifier);

try {
  await notifier.signInWithMagicLink(
    email: 'user@example.com',
  );
  // Show message: "Check your email for a login link"
} catch (e) {
  print('Magic link failed: $e');
}
```

### Password Reset

```dart
final notifier = ref.read(authProvider.notifier);

try {
  await notifier.requestPasswordReset(
    email: 'user@example.com',
  );
  // Show message: "Check your email for password reset instructions"
} catch (e) {
  print('Password reset failed: $e');
}
```

### Sign Out

```dart
final notifier = ref.read(authProvider.notifier);

try {
  await notifier.signOut();
  context.go('/auth/login');
} catch (e) {
  print('Sign out failed: $e');
}
```

## Protected Routes

The router automatically protects routes based on authentication status:

- **Authenticated-only routes**: `/dashboard`, `/crm`, `/ticketing`, `/settings`
  - Unauthenticated users are redirected to `/auth/login`
  
- **Auth routes**: `/auth/*`
  - Already authenticated users are redirected to `/dashboard`

## Role-Based Access Control

The application supports four user roles with different access levels:

### User Roles

1. **Admin** (`admin`)
   - Full access to all features and data
   - Can manage users, invitations, and system settings
   - Can view and modify all records

2. **Agent** (`agent`)
   - Can manage customers and tickets they own
   - Can view customer interactions
   - Limited to their assigned data

3. **Customer** (`customer`)
   - Can view their own profile and customer record
   - Can view tickets linked to their customer record
   - Can add comments to their tickets
   - Read-only access to their data

4. **Guest** (`guest`)
   - Read-only access to public dashboards
   - Cannot create or modify data
   - Returns empty datasets for most queries

### User Status

Each user has a status that affects their permissions:

- **Active** (`active`): Full access according to their role
- **Disabled** (`disabled`): Cannot mutate any data, blocked from write operations
- **Invited** (`invited`): User has been invited but hasn't signed up yet
- **Pending** (`pending`): User account is pending approval

### Implementation

The profiles table includes these fields:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role user_role DEFAULT 'agent' NOT NULL,
  status user_status DEFAULT 'active' NOT NULL,
  last_active_at TIMESTAMP WITH TIME ZONE,
  disabled_at TIMESTAMP WITH TIME ZONE,
  -- ... other fields
);
```

**RLS Policies** automatically enforce role-based permissions:
- All write operations check that `status != 'disabled'`
- Customers can only access their own data
- Guests have read-only access
- Admins bypass most restrictions

To implement role-based routing in Flutter:

```dart
if (isAuthenticated && !isAuthRoute) {
  final userRole = authState.userRole;
  final userStatus = authState.userStatus;
  
  // Block disabled users
  if (userStatus == 'disabled') {
    return '/unauthorized';
  }
  
  // Role-based routing
  if (state.uri.path == '/admin' && userRole != 'admin') {
    return '/dashboard';
  }
  
  // Guest users can only access public pages
  if (userRole == 'guest' && !publicRoutes.contains(state.uri.path)) {
    return '/public-dashboard';
  }
}
```

## Troubleshooting

### "SUPABASE_URL or SUPABASE_ANON_KEY is null"

- Ensure `.env` file exists in the project root
- Verify `pubspec.yaml` includes `.env` in assets
- Check that environment variables are correct

### "Invalid Redirect URI"

- Add your domain to Supabase **Authentication > URL Configuration**
- For development on localhost, use `http://localhost:3000`
- For mobile, ensure deep link configuration is correct

### "Session Expired"

- The app automatically refreshes sessions
- If still failing, log out and log back in
- Check Supabase project settings for JWT expiration time

### "User Creation Failed"

- Check that passwords are at least 6 characters
- Ensure email is valid and not already registered
- Verify invitation code if required

## Advanced Topics

### Hooks and Listeners

To listen to authentication changes:

```dart
@override
void initState() {
  super.initState();
  
  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      // Handle status change
      print('Auth status changed: ${next.status}');
    }
  });
}
```

### Using OAuth Providers

To add Google Sign-In:

```dart
// Update pubspec.yaml
dependencies:
  google_sign_in: ^6.0.0

// Use in your sign-in method
await ref.read(authProvider.notifier).signInWithGoogle();
```

### Custom Claims and Metadata

Store additional user data in `profiles` table:

```sql
UPDATE profiles
SET role = 'admin', extra_data = '{"department": "Sales"}'
WHERE id = 'user-id';
```

Access in app:

```dart
final profile = await datasource.fetchUserProfile(userId);
final role = profile['role'];
```

## Security Best Practices

1. **Never commit `.env`** - Add to `.gitignore`
2. **Use HTTPS only** in production
3. **Enable RLS** on all tables in Supabase
4. **Rotate secrets regularly**
5. **Use strong passwords** (at least 12 characters)
6. **Enable 2FA** for admin accounts
7. **Review Supabase security settings** regularly
8. **Keep dependencies updated**

## Testing

Run authentication tests:

```bash
flutter test test/auth/
flutter test test/routing/
```

## Support

For issues with:
- **Supabase**: [Supabase Docs](https://supabase.com/docs)
- **Flutter**: [Flutter Docs](https://flutter.dev/docs)
- **Riverpod**: [Riverpod Docs](https://riverpod.dev)

## License

This authentication module is part of the main application.
