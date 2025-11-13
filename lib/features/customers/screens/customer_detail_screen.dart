import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/customer_interaction_repository.dart';
import '../../../models/customer.dart';
import '../view_models/customers_view_model.dart';
import '../../interactions/screens/interactions_screen.dart';
import 'customer_edit_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    final repository = CustomerRepository();
    final result = await repository.getCustomerById(widget.customerId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _customer = result.dataOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerEditScreen(customer: _customer),
                ),
              );
              if (result == true) {
                _loadCustomer();
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') {
                _confirmArchive();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: Text('Archive'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    _customer!.name.isNotEmpty ? _customer!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(_customer!.status.toUpperCase()),
                        backgroundColor: _getStatusColor(_customer!.status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (_customer!.email != null) ...[
              _buildInfoRow(Icons.email, 'Email', _customer!.email!),
              const SizedBox(height: 12),
            ],
            if (_customer!.phone != null) ...[
              _buildInfoRow(Icons.phone, 'Phone', _customer!.phone!),
              const SizedBox(height: 12),
            ],
            if (_customer!.acquisitionSource != null) ...[
              _buildInfoRow(Icons.source, 'Source', _customer!.acquisitionSource!),
              const SizedBox(height: 12),
            ],
            if (_customer!.owner != null) ...[
              _buildInfoRow(Icons.person, 'Owner', _customer!.owner!),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(Icons.calendar_today, 'Created', dateFormat.format(_customer!.createdAt)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InteractionsScreen(customer: _customer!),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View Interactions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'lead':
        return Colors.blue[100]!;
      case 'qualified':
        return Colors.orange[100]!;
      case 'proposal':
        return Colors.purple[100]!;
      case 'closed_won':
        return Colors.green[100]!;
      case 'closed_lost':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Customer'),
        content: Text('Are you sure you want to archive "${_customer!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CustomersViewModel>().archiveCustomer(_customer!.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer archived')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to permanently delete "${_customer!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<CustomersViewModel>().deleteCustomer(_customer!.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted')),
        );
      }
    }
  }
}
