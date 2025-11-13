import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/result.dart';
import '../../../models/customer.dart';
import '../../../models/acquisition_stage.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import '../view_models/customers_view_model.dart';

class CustomerEditScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerEditScreen({
    super.key,
    this.customer,
  });

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _acquisitionSourceController;
  late TextEditingController _ownerController;
  String? _selectedProductId;
  late String _selectedStatus;
  bool _isSaving = false;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _emailController =
        TextEditingController(text: widget.customer?.email ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phone ?? '');
    _acquisitionSourceController =
        TextEditingController(text: widget.customer?.acquisitionSource ?? '');
    _ownerController =
        TextEditingController(text: widget.customer?.owner ?? '');
    _selectedProductId = widget.customer?.productId;
    _selectedStatus = widget.customer?.status ?? 'lead';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final repository = ProductRepository();
    final result = await repository.getProducts();
    if (mounted) {
      setState(() {
        _products = result.dataOrNull?.where((p) => p.isActive).toList() ?? [];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _acquisitionSourceController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.customer == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Customer' : 'Edit Customer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a customer name';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Product'),
                ),
                ..._products.map((product) {
                  return DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: AcquisitionStage.defaultStages.map((stage) {
                return DropdownMenuItem(
                  value: stage.id,
                  child: Text(stage.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _acquisitionSourceController,
              decoration: const InputDecoration(
                labelText: 'Acquisition Source',
                border: OutlineInputBorder(),
                hintText: 'e.g., Website, Referral, Cold Call',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Owner',
                border: OutlineInputBorder(),
                hintText: 'Sales representative name',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCustomer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isNew ? 'Create Customer' : 'Update Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = context.read<CustomersViewModel>();
    final now = DateTime.now();
    final uuid = const Uuid();

    final customer = Customer(
      id: widget.customer?.id ?? uuid.v4(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      productId: _selectedProductId,
      status: _selectedStatus,
      acquisitionSource: _acquisitionSourceController.text.trim().isEmpty
          ? null
          : _acquisitionSourceController.text.trim(),
      owner: _ownerController.text.trim().isEmpty
          ? null
          : _ownerController.text.trim(),
      isArchived: widget.customer?.isArchived ?? false,
      createdAt: widget.customer?.createdAt ?? now,
      updatedAt: now,
    );

    final success = widget.customer == null
        ? await viewModel.createCustomer(customer)
        : await viewModel.updateCustomer(customer);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customer == null
                ? 'Customer created'
                : 'Customer updated'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(viewModel.error?.message ?? 'Failed to save customer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
