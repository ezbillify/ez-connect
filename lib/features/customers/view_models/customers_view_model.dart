import 'package:flutter/foundation.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/customer.dart';
import '../../../repositories/customer_repository.dart';

class CustomersViewModel extends ChangeNotifier {
  final CustomerRepository _repository;

  CustomersViewModel(this._repository) {
    loadCustomers();
    _subscribeToCustomers();
  }

  List<Customer> _customers = [];
  bool _isLoading = false;
  AppError? _error;
  String _searchQuery = '';
  String? _filterProductId;
  String? _filterStatus;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadCustomers();
  }

  void setProductFilter(String? productId) {
    _filterProductId = productId;
    loadCustomers();
  }

  void setStatusFilter(String? status) {
    _filterStatus = status;
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getCustomers(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      productId: _filterProductId,
      status: _filterStatus,
    );

    result.fold(
      onSuccess: (customers) {
        _customers = customers;
        _isLoading = false;
        _error = null;
      },
      onFailure: (error) {
        _error = error;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<bool> createCustomer(Customer customer) async {
    final result = await _repository.createCustomer(customer);
    return result.fold(
      onSuccess: (_) {
        return true;
      },
      onFailure: (error) {
        _error = error;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> updateCustomer(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      final oldCustomer = _customers[index];
      _customers[index] = customer;
      notifyListeners();

      final result = await _repository.updateCustomer(customer);
      return result.fold(
        onSuccess: (_) {
          return true;
        },
        onFailure: (error) {
          _customers[index] = oldCustomer;
          _error = error;
          notifyListeners();
          return false;
        },
      );
    }
    return false;
  }

  Future<bool> archiveCustomer(String id) async {
    final result = await _repository.archiveCustomer(id);
    return result.fold(
      onSuccess: (_) {
        return true;
      },
      onFailure: (error) {
        _error = error;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> deleteCustomer(String id) async {
    final result = await _repository.deleteCustomer(id);
    return result.fold(
      onSuccess: (_) {
        return true;
      },
      onFailure: (error) {
        _error = error;
        notifyListeners();
        return false;
      },
    );
  }

  void _subscribeToCustomers() {
    _repository.watchCustomers().listen((customers) {
      _customers = customers;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
