import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/acquisition_stage.dart';
import '../../../models/customer.dart';
import '../../customers/view_models/customers_view_model.dart';
import '../../customers/screens/customer_detail_screen.dart';
import '../widgets/pipeline_stage_column.dart';

class AcquisitionPipelineScreen extends StatefulWidget {
  const AcquisitionPipelineScreen({super.key});

  @override
  State<AcquisitionPipelineScreen> createState() => _AcquisitionPipelineScreenState();
}

class _AcquisitionPipelineScreenState extends State<AcquisitionPipelineScreen> {
  bool _isKanbanView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acquisition Pipeline'),
        actions: [
          IconButton(
            icon: Icon(_isKanbanView ? Icons.list : Icons.view_column),
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomersViewModel>().loadCustomers();
            },
          ),
        ],
      ),
      body: Consumer<CustomersViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.customers.isEmpty) {
            return const Center(
              child: Text('No customers in the pipeline'),
            );
          }

          return _isKanbanView
              ? _buildKanbanView(viewModel.customers)
              : _buildListView(viewModel.customers);
        },
      ),
    );
  }

  Widget _buildKanbanView(List<Customer> customers) {
    final stages = AcquisitionStage.defaultStages;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        final stageCustomers = customers
            .where((c) => c.status == stage.id)
            .toList();

        return PipelineStageColumn(
          stage: stage,
          customers: stageCustomers,
          onCustomerTap: (customer) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customerId: customer.id),
              ),
            );
          },
          onCustomerMoved: (customer, newStageId) {
            _moveCustomer(customer, newStageId);
          },
        );
      },
    );
  }

  Widget _buildListView(List<Customer> customers) {
    final stages = AcquisitionStage.defaultStages;

    return ListView.builder(
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        final stageCustomers = customers
            .where((c) => c.status == stage.id)
            .toList();

        return ExpansionTile(
          title: Text(
            '${stage.name} (${stageCustomers.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          children: stageCustomers.map((customer) {
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(customer.name),
              subtitle: customer.email != null ? Text(customer.email!) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customerId: customer.id),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _moveCustomer(Customer customer, String newStageId) async {
    final updatedCustomer = customer.copyWith(
      status: newStageId,
      updatedAt: DateTime.now(),
    );

    final success = await context.read<CustomersViewModel>().updateCustomer(updatedCustomer);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.name} moved to ${_getStageName(newStageId)}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to move customer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStageName(String stageId) {
    return AcquisitionStage.defaultStages
        .firstWhere((s) => s.id == stageId)
        .name;
  }
}
