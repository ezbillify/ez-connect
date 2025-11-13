import 'package:app/domain/models/user.dart';

abstract class AuthRepository {
  /// Initialize the auth session on app startup
  Future<void> initializeSession();

  /// Sign in with email and password
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password (requires invitation if enabled)
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? invitationCode,
  });

  /// Request a password reset email
  Future<void> requestPasswordReset({required String email});

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Sign in with magic link (passwordless)
  Future<void> signInWithMagicLink({required String email});

  /// Get the user's role from cached metadata
  Future<String?> getUserRole();

  /// Fetch and cache the current user profile
  Future<User?> fetchUserProfile();

  /// Get the current user (from session)
  User? getCurrentUser();

  /// Check if user is authenticated
  bool isAuthenticated();

  /// Sign out the current user
  Future<void> signOut();

  /// Auto-refresh session tokens (call periodically)
  Future<void> refreshSession();

  /// Get auth error message
  String? getLastError();

  /// Clear auth errors
  void clearError();

  /// Stream of auth state changes
  Stream<AuthEvent> get authStateChanges;
}

/// Events emitted by auth state changes
abstract class AuthEvent {
  const AuthEvent();
}

class UserSignedInEvent extends AuthEvent {
  final User user;
  UserSignedInEvent(this.user);
}

class UserSignedOutEvent extends AuthEvent {
  const UserSignedOutEvent();
}

class UserUpdatedEvent extends AuthEvent {
  final User user;
  UserUpdatedEvent(this.user);
}

class AuthErrorEvent extends AuthEvent {
  final String message;
  AuthErrorEvent(this.message);
}

class SessionRefreshedEvent extends AuthEvent {
  const SessionRefreshedEvent();
}
