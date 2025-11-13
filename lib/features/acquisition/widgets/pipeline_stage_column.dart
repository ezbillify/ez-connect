import 'package:flutter/material.dart';
import '../../../models/acquisition_stage.dart';
import '../../../models/customer.dart';

class PipelineStageColumn extends StatelessWidget {
  final AcquisitionStage stage;
  final List<Customer> customers;
  final Function(Customer) onCustomerTap;
  final Function(Customer, String) onCustomerMoved;

  const PipelineStageColumn({
    super.key,
    required this.stage,
    required this.customers,
    required this.onCustomerTap,
    required this.onCustomerMoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStageColor(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stage.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${customers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: DragTarget<Customer>(
                onAcceptWithDetails: (details) {
                  if (details.data.status != stage.id) {
                    onCustomerMoved(details.data, stage.id);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Draggable<Customer>(
                        data: customer,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 260,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildCustomerCard(customer),
                        ),
                        child: _buildCustomerCard(customer),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onCustomerTap(customer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (customer.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  customer.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (customer.acquisitionSource != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    customer.acquisitionSource!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStageColor() {
    switch (stage.id) {
      case 'lead':
        return Colors.blue;
      case 'qualified':
        return Colors.orange;
      case 'proposal':
        return Colors.purple;
      case 'negotiation':
        return Colors.teal;
      case 'closed_won':
        return Colors.green;
      case 'closed_lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
