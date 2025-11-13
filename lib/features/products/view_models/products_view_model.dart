import 'package:flutter/foundation.dart';
import '../../../core/errors/app_error.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';

class ProductsViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  ProductsViewModel(this._repository) {
    loadProducts();
    _subscribeToProducts();
  }

  List<Product> _products = [];
  bool _isLoading = false;
  AppError? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  List<Product> get activeProducts => _products.where((p) => p.isActive).toList();

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getProducts();
    result.fold(
      onSuccess: (products) {
        _products = products;
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

  Future<bool> createProduct(Product product) async {
    final result = await _repository.createProduct(product);
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

  Future<bool> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final oldProduct = _products[index];
      _products[index] = product;
      notifyListeners();

      final result = await _repository.updateProduct(product);
      return result.fold(
        onSuccess: (_) {
          return true;
        },
        onFailure: (error) {
          _products[index] = oldProduct;
          _error = error;
          notifyListeners();
          return false;
        },
      );
    }
    return false;
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _repository.deleteProduct(id);
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

  void _subscribeToProducts() {
    _repository.watchProducts().listen((products) {
      _products = products;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
