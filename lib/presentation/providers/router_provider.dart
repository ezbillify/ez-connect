import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:app/presentation/screens/crm/crm_screen.dart';
import 'package:app/presentation/screens/ticketing/ticketing_screen.dart';
import 'package:app/presentation/screens/settings/settings_screen.dart';
import 'package:app/presentation/screens/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
    ],
  );
});
