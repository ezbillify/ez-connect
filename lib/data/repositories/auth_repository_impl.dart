import 'dart:async';
import 'package:app/data/datasources/supabase_auth_datasource.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDatasource datasource;
  String? _lastError;
  String? _cachedUserRole;
  User? _cachedUser;

  // Stream controller for auth state changes
  late StreamController<AuthEvent> _authEventController;
  late StreamSubscription<dynamic> _authStateSubscription;

  AuthRepositoryImpl({required this.datasource}) {
    _authEventController = StreamController<AuthEvent>.broadcast();
    _setupAuthStateListener();
  }

  @override
  Future<void> initializeSession() async {
    try {
      _lastError = null;
      final user = getCurrentUser();

      if (user != null) {
        _cachedUser = user;
        await fetchUserProfile();
        _authEventController.add(UserSignedInEvent(user));
      }

      // Auto-refresh session
      unawaited(refreshSession());
    } catch (e) {
      _lastError = e.toString();
      _authEventController.add(AuthErrorEvent(_lastError!));
    }
  }

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _lastError = null;
      final user = await datasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _cachedUser = user;
      await fetchUserProfile();
      _authEventController.add(UserSignedInEvent(user));
      return user;
    } catch (e) {
      _lastError = 'Failed to sign in: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? invitationCode,
  }) async {
    try {
      _lastError = null;

      // Validate invitation code if required
      if (invitationCode != null && invitationCode.isNotEmpty) {
        final isValid = await datasource.validateInvitationCode(invitationCode);
        if (!isValid) {
          throw Exception('Invalid or already used invitation code');
        }
      }

      final user = await datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      // Mark invitation as used if provided
      if (invitationCode != null && invitationCode.isNotEmpty) {
        await datasource.markInvitationAsUsed(invitationCode);
      }

      _cachedUser = user;
      await fetchUserProfile();
      _authEventController.add(UserSignedInEvent(user));
      return user;
    } catch (e) {
      _lastError = 'Failed to sign up: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      _lastError = null;
      await datasource.requestPasswordReset(email: email);
    } catch (e) {
      _lastError = 'Failed to request password reset: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _lastError = null;
      await datasource.resetPassword(token: token, newPassword: newPassword);
    } catch (e) {
      _lastError = 'Failed to reset password: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<void> signInWithMagicLink({required String email}) async {
    try {
      _lastError = null;
      await datasource.signInWithMagicLink(email: email);
    } catch (e) {
      _lastError = 'Failed to send magic link: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<String?> getUserRole() async {
    if (_cachedUserRole != null) {
      return _cachedUserRole;
    }

    try {
      final profile = await datasource.fetchUserProfile(_cachedUser?.id ?? '');
      _cachedUserRole = profile?['role'] as String?;
      return _cachedUserRole;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> fetchUserProfile() async {
    if (_cachedUser == null) {
      return null;
    }

    try {
      final profile = await datasource.fetchUserProfile(_cachedUser!.id);
      if (profile != null) {
        _cachedUserRole = profile['role'] as String?;
        _cachedUser = _cachedUser!.copyWith(role: _cachedUserRole);
      }
      return _cachedUser;
    } catch (e) {
      return _cachedUser;
    }
  }

  @override
  User? getCurrentUser() {
    return datasource.getCurrentUser();
  }

  @override
  bool isAuthenticated() {
    return datasource.getCurrentSession() != null;
  }

  @override
  Future<void> signOut() async {
    try {
      _lastError = null;
      await datasource.signOut();
      _cachedUser = null;
      _cachedUserRole = null;
      _authEventController.add(const UserSignedOutEvent());
    } catch (e) {
      _lastError = 'Failed to sign out: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
      rethrow;
    }
  }

  @override
  Future<void> refreshSession() async {
    try {
      final success = await datasource.refreshSession();
      if (success) {
        final user = getCurrentUser();
        if (user != null) {
          _cachedUser = user;
          await fetchUserProfile();
          _authEventController.add(const SessionRefreshedEvent());
        }
      }
    } catch (e) {
      _lastError = 'Failed to refresh session: ${e.toString()}';
      _authEventController.add(AuthErrorEvent(_lastError!));
    }
  }

  @override
  String? getLastError() => _lastError;

  @override
  void clearError() {
    _lastError = null;
  }

  @override
  Stream<AuthEvent> get authStateChanges => _authEventController.stream;

  void _setupAuthStateListener() {
    _authStateSubscription = datasource.authStateChanges().listen(
      (state) {
        if (state.session != null) {
          final user = getCurrentUser();
          if (user != null) {
            _cachedUser = user;
            _authEventController.add(UserSignedInEvent(user));
          }
        } else {
          _cachedUser = null;
          _cachedUserRole = null;
          _authEventController.add(const UserSignedOutEvent());
        }
      },
      onError: (error) {
        _lastError = error.toString();
        _authEventController.add(AuthErrorEvent(_lastError!));
      },
    );
  }

  void dispose() {
    _authStateSubscription.cancel();
    _authEventController.close();
  }
}
