import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/customer.dart';
import '../../../models/customer_interaction.dart';
import '../../../repositories/customer_interaction_repository.dart';
import 'add_interaction_screen.dart';

class InteractionsScreen extends StatefulWidget {
  final Customer customer;

  const InteractionsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<InteractionsScreen> createState() => _InteractionsScreenState();
}

class _InteractionsScreenState extends State<InteractionsScreen> {
  final CustomerInteractionRepository _repository = CustomerInteractionRepository();
  List<CustomerInteraction> _interactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInteractions();
    _subscribeToInteractions();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadInteractions() async {
    final result = await _repository.getInteractionsByCustomerId(widget.customer.id);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _interactions = result.dataOrNull ?? [];
      });
    }
  }

  void _subscribeToInteractions() {
    _repository.watchInteractions(widget.customer.id).listen((interactions) {
      if (mounted) {
        setState(() {
          _interactions = interactions;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name} - Interactions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _interactions.isEmpty
              ? const Center(
                  child: Text('No interactions yet. Add one to get started!'),
                )
              : RefreshIndicator(
                  onRefresh: _loadInteractions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _interactions.length,
                    itemBuilder: (context, index) {
                      final interaction = _interactions[index];
                      return _buildInteractionCard(interaction);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddInteractionScreen(customer: widget.customer),
            ),
          );
          if (result == true) {
            _loadInteractions();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Interaction'),
      ),
    );
  }

  Widget _buildInteractionCard(CustomerInteraction interaction) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getChannelIcon(interaction.channel),
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  interaction.channel.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(interaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              interaction.type,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              interaction.note,
              style: const TextStyle(fontSize: 14),
            ),
            if (interaction.followUpDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange[900]),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-up: ${DateFormat('MMM dd, yyyy').format(interaction.followUpDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getChannelIcon(InteractionChannel channel) {
    switch (channel) {
      case InteractionChannel.phone:
        return Icons.phone;
      case InteractionChannel.email:
        return Icons.email;
      case InteractionChannel.meeting:
        return Icons.people;
      case InteractionChannel.chat:
        return Icons.chat;
      case InteractionChannel.other:
        return Icons.more_horiz;
    }
  }
}
