import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/database_constants.dart';
import '../core/errors/app_error.dart';
import '../core/utils/result.dart';
import '../models/product.dart';

class ProductRepository {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  ProductRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<Result<List<Product>>> getProducts() async {
    try {
      final response = await _client
          .from(DatabaseConstants.productsTable)
          .select()
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();

      return Success(products);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to fetch products', e));
    }
  }

  Future<Result<Product>> getProductById(String id) async {
    try {
      final response = await _client
          .from(DatabaseConstants.productsTable)
          .select()
          .eq('id', id)
          .single();

      return Success(Product.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Failure(NotFoundError('Product'));
      }
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to fetch product', e));
    }
  }

  Future<Result<Product>> createProduct(Product product) async {
    try {
      if (product.isActive) {
        final activeCountResult = await _getActiveProductCount();
        if (activeCountResult.isFailure) {
          return Failure(activeCountResult.errorOrNull!);
        }
        if (activeCountResult.dataOrNull! >= DatabaseConstants.maxActiveProducts) {
          return const Failure(MaxProductsError());
        }
      }

      final response = await _client
          .from(DatabaseConstants.productsTable)
          .insert(product.toJson())
          .select()
          .single();

      return Success(Product.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to create product', e));
    }
  }

  Future<Result<Product>> updateProduct(Product product) async {
    try {
      if (product.isActive) {
        final activeCountResult = await _getActiveProductCount(excludeId: product.id);
        if (activeCountResult.isFailure) {
          return Failure(activeCountResult.errorOrNull!);
        }
        if (activeCountResult.dataOrNull! >= DatabaseConstants.maxActiveProducts) {
          return const Failure(MaxProductsError());
        }
      }

      final response = await _client
          .from(DatabaseConstants.productsTable)
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();

      return Success(Product.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to update product', e));
    }
  }

  Future<Result<void>> deleteProduct(String id) async {
    try {
      await _client
          .from(DatabaseConstants.productsTable)
          .delete()
          .eq('id', id);

      return const Success(null);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to delete product', e));
    }
  }

  Future<Result<int>> _getActiveProductCount({String? excludeId}) async {
    try {
      var query = _client
          .from(DatabaseConstants.productsTable)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('is_active', true);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return Success(response.count);
    } catch (e) {
      return Failure(DatabaseError('Failed to count active products', e));
    }
  }

  Stream<List<Product>> watchProducts() {
    final controller = StreamController<List<Product>>();

    _subscription = _client
        .from(DatabaseConstants.productsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          final products = data.map((json) => Product.fromJson(json)).toList();
          controller.add(products);
        });

    return controller.stream;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
