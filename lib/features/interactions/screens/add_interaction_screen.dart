import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../models/customer.dart';
import '../../../models/customer_interaction.dart';
import '../../../repositories/customer_interaction_repository.dart';

class AddInteractionScreen extends StatefulWidget {
  final Customer customer;

  const AddInteractionScreen({
    super.key,
    required this.customer,
  });

  @override
  State<AddInteractionScreen> createState() => _AddInteractionScreenState();
}

class _AddInteractionScreenState extends State<AddInteractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _noteController = TextEditingController();
  InteractionChannel _selectedChannel = InteractionChannel.phone;
  DateTime? _followUpDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _typeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Interaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Customer: ${widget.customer.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Interaction Type',
                border: OutlineInputBorder(),
                hintText: 'e.g., Initial Contact, Follow-up Call',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an interaction type';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<InteractionChannel>(
              initialValue: _selectedChannel,
              decoration: const InputDecoration(
                labelText: 'Channel',
                border: OutlineInputBorder(),
              ),
              items: InteractionChannel.values.map((channel) {
                return DropdownMenuItem(
                  value: channel,
                  child: Row(
                    children: [
                      Icon(_getChannelIcon(channel), size: 20),
                      const SizedBox(width: 8),
                      Text(channel.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedChannel = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                hintText: 'Enter details about this interaction',
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter notes';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                _followUpDate == null
                    ? 'No follow-up scheduled'
                    : 'Follow-up: ${DateFormat('MMM dd, yyyy').format(_followUpDate!)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_followUpDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _followUpDate = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickFollowUpDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveInteraction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Interaction'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _followUpDate = date;
      });
    }
  }

  Future<void> _saveInteraction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final interaction = CustomerInteraction(
      id: const Uuid().v4(),
      customerId: widget.customer.id,
      type: _typeController.text.trim(),
      channel: _selectedChannel,
      note: _noteController.text.trim(),
      followUpDate: _followUpDate,
      createdAt: DateTime.now(),
    );

    final repository = CustomerInteractionRepository();
    final result = await repository.createInteraction(interaction);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result.isSuccess) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction saved')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorOrNull?.message ?? 'Failed to save interaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
