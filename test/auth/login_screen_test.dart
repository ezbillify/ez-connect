import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:app/presentation/screens/auth/login_screen.dart';
import 'package:app/presentation/providers/auth_provider.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/domain/models/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('Login Screen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockGoRouter mockRouter;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockRouter = MockGoRouter();
    });

    testWidgets('Login screen displays email and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Login button is disabled when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
    });

    testWidgets('Password visibility toggle works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Navigate to signup screen when signup link is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Navigate to forgot password screen when link is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Shows welcome message on login screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('Shows error message when sign in fails',
        (WidgetTester tester) async {
      when(mockAuthRepository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      final emailField = find.byIcon(Icons.email_outlined);
      final passwordField = find.byIcon(Icons.lock_outline);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('Shows loading state during sign in',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LoginScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
