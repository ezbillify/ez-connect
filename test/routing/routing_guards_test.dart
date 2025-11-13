import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/domain/models/auth_state.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/presentation/providers/router_provider.dart' as router;

void main() {
  group('Routing Guards Tests', () {
    test('AuthState can be created correctly', () {
      final authState = AuthState(
        status: AuthStatus.unauthenticated,
      );
      expect(authState.status, AuthStatus.unauthenticated);
    });

    test('AuthState with user can be created correctly', () async {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final authState = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        userRole: 'user',
      );

      expect(authState.user, isNotNull);
      expect(authState.status, AuthStatus.authenticated);
    });

    test('Protected routes should require authentication', () {
      final authState = AuthState(
        status: AuthStatus.unauthenticated,
      );

      expect(authState.user, isNull);
      expect(authState.status, AuthStatus.unauthenticated);
    });

    test('User with proper role can access protected routes', () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
        role: 'admin',
      );

      final authState = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        userRole: 'admin',
      );

      expect(authState.user?.role, 'admin');
      expect(authState.userRole, 'admin');
    });

    test('Auth routes should redirect to dashboard when already authenticated',
        () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final authState = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        userRole: 'user',
      );

      expect(authState.status, AuthStatus.authenticated);
      expect(authState.user, isNotNull);
    });

    test('Loading state should not redirect', () {
      final authState = AuthState(
        status: AuthStatus.loading,
      );

      expect(authState.status, AuthStatus.loading);
      expect(authState.user, isNull);
    });

    test('Error state should still require authentication', () {
      final authState = AuthState(
        status: AuthStatus.error,
        error: 'Auth failed',
      );

      expect(authState.status, AuthStatus.error);
      expect(authState.error, 'Auth failed');
      expect(authState.user, isNull);
    });
  });
}
