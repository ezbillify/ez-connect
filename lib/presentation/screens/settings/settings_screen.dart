import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Gap(8),
              Text(
                'Manage your application settings',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Gap(32),
              if (currentUser != null) ...[
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Gap(16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: currentUser.avatarUrl != null
                                ? NetworkImage(currentUser.avatarUrl!)
                                : null,
                            child: currentUser.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(currentUser.name),
                          subtitle: Text(currentUser.email),
                        ),
                        const Gap(16),
                        Divider(color: Colors.grey[300]),
                        const Gap(16),
                        Row(
                          children: [
                            Icon(Icons.mail, color: Colors.grey[600]),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  Text(
                                    currentUser.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        if (userRole != null)
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.grey[600]),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Role',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    Text(
                                      userRole,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Gap(16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/auth/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
