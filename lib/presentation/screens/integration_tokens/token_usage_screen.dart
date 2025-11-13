import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:app/presentation/providers/integration_token_provider.dart';
import 'package:app/domain/models/integration_token.dart';
import 'package:intl/intl.dart';

class TokenUsageScreen extends ConsumerWidget {
  final String tokenId;

  const TokenUsageScreen({Key? key, required this.tokenId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(integrationTokenUsageProvider(tokenId));
    final statsAsync = ref.watch(integrationTokenStatsProvider(tokenId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Usage'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/integration-tokens'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usage Statistics',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Gap(8),
              Text(
                'View API usage and statistics for this token',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Gap(32),
              statsAsync.when(
                data: (stats) => _buildStatsCards(context, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading stats: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const Gap(32),
              Text(
                'Recent Requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Gap(16),
              usageAsync.when(
                data: (usage) => usage.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const Gap(16),
                                Text(
                                  'No usage data yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Gap(8),
                                Text(
                                  'API requests will appear here once this token is used',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: usage.length,
                        separatorBuilder: (context, index) => const Gap(8),
                        itemBuilder: (context, index) {
                          final request = usage[index];
                          return UsageCard(usage: request);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading usage: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, IntegrationTokenStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;

        if (width > 1200) {
          crossAxisCount = 4;
        } else if (width > 800) {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.all_inclusive,
              label: 'Total Requests',
              value: stats.totalRequests.toString(),
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.schedule,
              label: 'This Hour',
              value: stats.requestsThisHour.toString(),
              color: Colors.green,
            ),
            _StatCard(
              icon: Icons.today,
              label: 'Today',
              value: stats.requestsToday.toString(),
              color: Colors.orange,
            ),
            _StatCard(
              icon: Icons.error,
              label: 'Errors',
              value: stats.errorCount.toString(),
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const Gap(8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class UsageCard extends StatelessWidget {
  final IntegrationTokenUsage usage;

  const UsageCard({Key? key, required this.usage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');
    final isError = usage.statusCode >= 400;
    final statusColor = isError ? Colors.red : Colors.green;

    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMethodColor(usage.method).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            usage.method,
            style: TextStyle(
              color: _getMethodColor(usage.method),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          usage.endpoint,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Text(dateFormat.format(usage.createdAt)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (usage.responseTimeMs != null) ...[
              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
              const Gap(4),
              Text(
                '${usage.responseTimeMs}ms',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Gap(16),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                usage.statusCode.toString(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usage.ipAddress != null) ...[
                  _DetailRow(label: 'IP Address', value: usage.ipAddress!),
                  const Gap(8),
                ],
                if (usage.userAgent != null) ...[
                  _DetailRow(label: 'User Agent', value: usage.userAgent!),
                  const Gap(8),
                ],
                if (usage.errorMessage != null) ...[
                  _DetailRow(
                    label: 'Error',
                    value: usage.errorMessage!,
                    isError: true,
                  ),
                  const Gap(8),
                ],
                if (usage.requestPayload != null) ...[
                  const Text(
                    'Request Payload:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      usage.requestPayload.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isError ? Colors.red : null,
            ),
          ),
        ),
      ],
    );
  }
}
