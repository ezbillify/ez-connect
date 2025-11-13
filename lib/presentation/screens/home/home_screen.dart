import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Home'),
        actions: [
          if (currentUser != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Profile'),
                  onTap: () => context.push('/settings'),
                ),
                PopupMenuItem(
                  child: const Text('Sign Out'),
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/auth/login');
                    }
                  },
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome ${currentUser?.name ?? 'to Your App'}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Gap(8),
              Text(
                currentUser != null
                    ? 'Explore the modules below'
                    : 'Sign in to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (userRole != null) ...[
                const Gap(8),
                Chip(
                  label: Text('Role: $userRole'),
                ),
              ],
              const Gap(32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _ModuleCard(
                    title: 'Dashboard',
                    icon: Icons.dashboard,
                    onTap: () => context.go('/dashboard'),
                  ),
                  _ModuleCard(
                    title: 'CRM',
                    icon: Icons.people,
                    onTap: () => context.go('/crm'),
                  ),
                  _ModuleCard(
                    title: 'Ticketing',
                    icon: Icons.confirmation_number,
                    onTap: () => context.go('/ticketing'),
                  ),
                  _ModuleCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const Gap(16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
