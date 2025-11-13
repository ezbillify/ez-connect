import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:app/presentation/providers/integration_token_provider.dart';
import 'package:app/domain/models/integration_token.dart';
import 'package:intl/intl.dart';

class IntegrationTokensScreen extends ConsumerStatefulWidget {
  const IntegrationTokensScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IntegrationTokensScreen> createState() =>
      _IntegrationTokensScreenState();
}

class _IntegrationTokensScreenState
    extends ConsumerState<IntegrationTokensScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(integrationTokenProvider.notifier).loadTokens();
    });
  }

  void _showCreateTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTokenDialog(),
    );
  }

  void _showTokenDialog(String token, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Token Created Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Token: $name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            const Text(
              'Make sure to copy your token now. You won\'t be able to see it again!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(integrationTokenProvider.notifier).clearNewToken();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(integrationTokenProvider);
    final statsAsync = ref.watch(allIntegrationTokenStatsProvider);

    ref.listen<IntegrationTokenState>(integrationTokenProvider, (previous, next) {
      if (next.newlyCreatedToken != null) {
        _showTokenDialog(
          next.newlyCreatedToken!.fullToken,
          next.newlyCreatedToken!.token.name,
        );
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(integrationTokenProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integration Tokens'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: state.isLoading && state.tokens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'API Integration Tokens',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const Gap(8),
                              Text(
                                'Manage tokens for external API integrations',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCreateTokenDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Token'),
                        ),
                      ],
                    ),
                    const Gap(32),
                    statsAsync.when(
                      data: (stats) {
                        if (stats.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return TokenStatsOverview(stats: stats);
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: LinearProgressIndicator(),
                      ),
                      error: (error, stack) => Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Failed to load usage statistics: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    const Gap(24),
                    if (state.tokens.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.key,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const Gap(16),
                                Text(
                                  'No integration tokens yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Gap(8),
                                Text(
                                  'Create your first token to enable external integrations',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.tokens.length,
                        separatorBuilder: (context, index) => const Gap(16),
                        itemBuilder: (context, index) {
                          final token = state.tokens[index];
                          return TokenCard(token: token);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class TokenStatsOverview extends StatelessWidget {
  final List<IntegrationTokenStats> stats;

  const TokenStatsOverview({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeTokens = stats.where((s) => s.status == 'active').length;
    final requestsThisHour = stats.fold<int>(0, (sum, stat) => sum + stat.requestsThisHour);
    final requestsToday = stats.fold<int>(0, (sum, stat) => sum + stat.requestsToday);
    final errorCount = stats.fold<int>(0, (sum, stat) => sum + stat.errorCount);

    final responseTimes = stats
        .where((stat) => stat.avgResponseTimeMs != null)
        .map((stat) => stat.avgResponseTimeMs!)
        .toList();

    final averageResponseTime = responseTimes.isNotEmpty
        ? responseTimes.reduce((value, element) => value + element) / responseTimes.length
        : null;

    final metricWidgets = <Widget>[
      _OverviewStat(
        icon: Icons.vpn_key,
        label: 'Active Tokens',
        value: activeTokens.toString(),
        color: Colors.green,
      ),
      _OverviewStat(
        icon: Icons.schedule,
        label: 'Requests (This Hour)',
        value: requestsThisHour.toString(),
        color: Colors.blue,
      ),
      _OverviewStat(
        icon: Icons.today,
        label: 'Requests (Today)',
        value: requestsToday.toString(),
        color: Colors.orange,
      ),
      _OverviewStat(
        icon: Icons.error_outline,
        label: 'Errors',
        value: errorCount.toString(),
        color: Colors.red,
      ),
    ];

    if (averageResponseTime != null) {
      metricWidgets.add(
        _OverviewStat(
          icon: Icons.timer,
          label: 'Avg Response',
          value: '${averageResponseTime.toStringAsFixed(0)} ms',
          color: Colors.purple,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            if (constraints.maxWidth > 1100) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth > 500) {
              crossAxisCount = 2;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: metricWidgets,
            );
          },
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

class TokenCard extends ConsumerWidget {
  final IntegrationToken token;

  const TokenCard({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isActive = token.status == 'active';
    final isExpired =
        token.expiresAt != null && token.expiresAt!.isBefore(DateTime.now());

    Color statusColor;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isActive) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            token.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Gap(12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isExpired
                                  ? 'Expired'
                                  : token.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (token.description != null) ...[
                        const Gap(4),
                        Text(
                          token.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'view_usage':
                        context.go('/integration-tokens/${token.id}/usage');
                        break;
                      case 'edit':
                        showDialog(
                          context: context,
                          builder: (context) => EditTokenDialog(token: token),
                        );
                        break;
                      case 'regenerate':
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Regenerate Token'),
                            content: const Text(
                              'Are you sure you want to regenerate this token? '
                              'The old token will stop working immediately.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Regenerate'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref
                              .read(integrationTokenProvider.notifier)
                              .regenerateToken(token.id);
                        }
                        break;
                      case 'toggle_status':
                        final newStatus =
                            isActive ? 'disabled' : 'active';
                        ref
                            .read(integrationTokenProvider.notifier)
                            .updateTokenStatus(id: token.id, status: newStatus);
                        break;
                      case 'delete':
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Token'),
                            content: const Text(
                              'Are you sure you want to delete this token? '
                              'This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref
                              .read(integrationTokenProvider.notifier)
                              .deleteToken(token.id);
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_usage',
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart),
                          Gap(8),
                          Text('View Usage'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          Gap(8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'regenerate',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          Gap(8),
                          Text('Regenerate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(isActive ? Icons.block : Icons.check_circle),
                          const Gap(8),
                          Text(isActive ? 'Disable' : 'Enable'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          Gap(8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Gap(16),
            Divider(color: Colors.grey[300]),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.key,
                    label: 'Token',
                    value: '${token.tokenPrefix}...',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.speed,
                    label: 'Rate Limit',
                    value: '${token.rateLimitPerHour}/hour',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.access_time,
                    label: 'Created',
                    value: dateFormat.format(token.createdAt),
                  ),
                ),
                if (token.lastUsedAt != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.access_time,
                      label: 'Last Used',
                      value: dateFormat.format(token.lastUsedAt!),
                    ),
                  ),
              ],
            ),
            if (token.expiresAt != null) ...[
              const Gap(12),
              _InfoItem(
                icon: Icons.event,
                label: 'Expires',
                value: dateFormat.format(token.expiresAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const Gap(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class CreateTokenDialog extends ConsumerStatefulWidget {
  const CreateTokenDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTokenDialog> createState() => _CreateTokenDialogState();
}

class _CreateTokenDialogState extends ConsumerState<CreateTokenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateLimitController = TextEditingController(text: '1000');
  DateTime? _expiresAt;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Integration Token'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Token Name',
                  hintText: 'e.g., Production API Token',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const Gap(16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this token used for?',
                ),
                maxLines: 3,
              ),
              const Gap(16),
              TextFormField(
                controller: _rateLimitController,
                decoration: const InputDecoration(
                  labelText: 'Rate Limit (requests/hour)',
                  hintText: '1000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate limit';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const Gap(16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiration Date (optional)'),
                subtitle: Text(
                  _expiresAt != null
                      ? DateFormat('MMM dd, yyyy').format(_expiresAt!)
                      : 'Never expires',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _expiresAt = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiresAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _expiresAt = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(integrationTokenProvider.notifier).createToken(
                    name: _nameController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    rateLimitPerHour: int.parse(_rateLimitController.text),
                    expiresAt: _expiresAt,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class EditTokenDialog extends ConsumerStatefulWidget {
  final IntegrationToken token;

  const EditTokenDialog({Key? key, required this.token}) : super(key: key);

  @override
  ConsumerState<EditTokenDialog> createState() => _EditTokenDialogState();
}

class _EditTokenDialogState extends ConsumerState<EditTokenDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rateLimitController;
  late DateTime? _expiresAt;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.token.name);
    _descriptionController =
        TextEditingController(text: widget.token.description ?? '');
    _rateLimitController =
        TextEditingController(text: widget.token.rateLimitPerHour.toString());
    _expiresAt = widget.token.expiresAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Integration Token'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Token Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const Gap(16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const Gap(16),
              TextFormField(
                controller: _rateLimitController,
                decoration: const InputDecoration(
                  labelText: 'Rate Limit (requests/hour)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate limit';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const Gap(16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiration Date (optional)'),
                subtitle: Text(
                  _expiresAt != null
                      ? DateFormat('MMM dd, yyyy').format(_expiresAt!)
                      : 'Never expires',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _expiresAt = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiresAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _expiresAt = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(integrationTokenProvider.notifier).updateToken(
                    id: widget.token.id,
                    name: _nameController.text,
                    description: _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                    rateLimitPerHour: int.parse(_rateLimitController.text),
                    expiresAt: _expiresAt,
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
