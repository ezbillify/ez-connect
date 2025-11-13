import 'package:flutter/material.dart';
import '../../../models/customer.dart';

class CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.email != null)
              Text(customer.email!),
            if (customer.phone != null)
              Text(customer.phone!),
          ],
        ),
        trailing: Chip(
          label: Text(
            customer.status.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getStatusColor(customer.status),
        ),
      ),
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
}
