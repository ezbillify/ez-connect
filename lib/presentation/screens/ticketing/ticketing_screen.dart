import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:app/presentation/providers/realtime_provider.dart';
import 'package:app/shared/widgets/realtime_status_indicator.dart';

class TicketingScreen extends ConsumerWidget {
  const TicketingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(realtimeConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticketing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: RealtimeStatusIndicator(showLabel: true),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const RealtimeConnectionBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticketing Module',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const Gap(8),
                    Text(
                      'Create and manage support tickets',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Gap(32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ticketing Module',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (connectionStatus.toString().endsWith('.connected'))
                                  const LiveUpdateIndicator(),
                              ],
                            ),
                            const Gap(12),
                            Text(
                              'This is a placeholder for the ticketing module. Add your ticketing features here.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
