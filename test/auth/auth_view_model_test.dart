import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:app/domain/models/auth_state.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Auth ViewModel Tests', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    test('Initial state should be AuthStatus.initial', () {
      final authState = container.read(authProvider);
      expect(authState.status, AuthStatus.initial);
      expect(authState.user, isNull);
      expect(authState.error, isNull);
    });

    test('signInWithEmailAndPassword should update state on success', () async {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.getUserRole()).thenAnswer((_) async => 'user');

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.id, '123');
      expect(state.user?.email, 'test@example.com');
      expect(state.userRole, 'user');
    });

    test('signInWithEmailAndPassword should set error on failure', () async {
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid credentials'));

      final notifier = container.read(authProvider.notifier);
      expect(
        () => notifier.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
        throwsException,
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.error);
    });

    test('signOut should clear auth state', () async {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.getUserRole()).thenAnswer((_) async => 'user');

      // Sign in first
      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(container.read(authProvider).status, AuthStatus.authenticated);

      // Sign out
      when(mockAuthRepository.signOut()).thenAnswer((_) async => {});
      await notifier.signOut();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.userRole, isNull);
    });

    test('signUpWithEmailAndPassword should create new user', () async {
      final testUser = User(
        id: '456',
        email: 'newuser@example.com',
        name: 'New User',
        createdAt: DateTime.now(),
      );

      when(mockAuthRepository.signUpWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'password123',
        name: 'New User',
        invitationCode: null,
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.getUserRole()).thenAnswer((_) async => 'user');

      final notifier = container.read(authProvider.notifier);
      await notifier.signUpWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'password123',
        name: 'New User',
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'newuser@example.com');
    });

    test('clearError should reset error message', () {
      final notifier = container.read(authProvider.notifier);
      notifier.clearError();

      final state = container.read(authProvider);
      expect(state.error, isNull);
    });

    test('isAuthenticatedProvider should return true when authenticated',
        () async {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.getUserRole()).thenAnswer((_) async => 'user');

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      final isAuthenticated = container.read(isAuthenticatedProvider);
      expect(isAuthenticated, true);
    });

    test('currentUserProvider should return current user', () async {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.getUserRole()).thenAnswer((_) async => 'user');

      final notifier = container.read(authProvider.notifier);
      await notifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      final currentUser = container.read(currentUserProvider);
      expect(currentUser?.id, '123');
      expect(currentUser?.email, 'test@example.com');
    });
  });
}
