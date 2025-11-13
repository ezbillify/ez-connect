import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:app/presentation/screens/crm/crm_screen.dart';
import 'package:app/presentation/screens/ticketing/ticketing_screen.dart';
import 'package:app/presentation/screens/settings/settings_screen.dart';
import 'package:app/presentation/screens/home/home_screen.dart';
import 'package:app/presentation/screens/auth/login_screen.dart';
import 'package:app/presentation/screens/auth/signup_screen.dart';
import 'package:app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:app/presentation/screens/auth/magic_link_screen.dart';
import 'package:app/presentation/providers/auth_provider.dart';
import 'package:app/domain/models/auth_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isAuthenticated = authState.status == AuthStatus.authenticated;

  return GoRouter(
    initialLocation: isAuthenticated ? '/dashboard' : '/auth/login',
    redirect: (context, state) {
      final isAuthRoute = state.uri.path.startsWith('/auth');

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      // Check role-based access for protected routes
      if (isAuthenticated && !isAuthRoute) {
        final userRole = authState.userRole;
        
        // CRM and Ticketing routes might require specific roles in future
        if ((state.uri.path == '/crm' || state.uri.path == '/ticketing') &&
            userRole == null) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/crm',
        builder: (context, state) => const CRMScreen(),
      ),
      GoRoute(
        path: '/ticketing',
        builder: (context, state) => const TicketingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/magic-link',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return MagicLinkScreen(email: email);
        },
      ),
    ],
  );
});
