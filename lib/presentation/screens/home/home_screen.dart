import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Home'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Your App',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Gap(8),
              Text(
                'Explore the modules below',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
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
