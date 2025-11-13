import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/customers_view_model.dart';
import '../widgets/customer_list_item.dart';
import 'customer_detail_screen.dart';
import 'customer_edit_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomersViewModel>().loadCustomers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CustomersViewModel>().setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<CustomersViewModel>().setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<CustomersViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading && viewModel.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null && viewModel.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.error!.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[300]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.loadCustomers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.customers.isEmpty) {
                  return const Center(
                    child: Text('No customers found. Create one to get started!'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadCustomers(),
                  child: ListView.builder(
                    itemCount: viewModel.customers.length,
                    itemBuilder: (context, index) {
                      final customer = viewModel.customers[index];
                      return CustomerListItem(
                        customer: customer,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customerId: customer.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('All Customers'),
                onTap: () {
                  context.read<CustomersViewModel>().setStatusFilter(null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Leads'),
                onTap: () {
                  context.read<CustomersViewModel>().setStatusFilter('lead');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Qualified'),
                onTap: () {
                  context.read<CustomersViewModel>().setStatusFilter('qualified');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Closed Won'),
                onTap: () {
                  context.read<CustomersViewModel>().setStatusFilter('closed_won');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
