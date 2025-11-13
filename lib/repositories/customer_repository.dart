import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/database_constants.dart';
import '../core/errors/app_error.dart';
import '../core/utils/result.dart';
import '../models/customer.dart';

class CustomerRepository {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  CustomerRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<Result<List<Customer>>> getCustomers({
    bool includeArchived = false,
    String? searchQuery,
    String? productId,
    String? status,
  }) async {
    try {
      var query = _client.from(DatabaseConstants.customersTable).select();

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
            'name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
      }

      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      final customers =
          (response as List).map((json) => Customer.fromJson(json)).toList();

      return Success(customers);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to fetch customers', e));
    }
  }

  Future<Result<Customer>> getCustomerById(String id) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customersTable)
          .select()
          .eq('id', id)
          .single();

      return Success(Customer.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Failure(NotFoundError('Customer'));
      }
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to fetch customer', e));
    }
  }

  Future<Result<Customer>> createCustomer(Customer customer) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customersTable)
          .insert(customer.toJson())
          .select()
          .single();

      return Success(Customer.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to create customer', e));
    }
  }

  Future<Result<Customer>> updateCustomer(Customer customer) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customersTable)
          .update(customer.toJson())
          .eq('id', customer.id)
          .select()
          .single();

      return Success(Customer.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to update customer', e));
    }
  }

  Future<Result<void>> archiveCustomer(String id) async {
    try {
      await _client.from(DatabaseConstants.customersTable).update({
        'is_archived': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', id);

      return const Success(null);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to archive customer', e));
    }
  }

  Future<Result<void>> deleteCustomer(String id) async {
    try {
      await _client
          .from(DatabaseConstants.customersTable)
          .delete()
          .eq('id', id);

      return const Success(null);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to delete customer', e));
    }
  }

  Stream<List<Customer>> watchCustomers({
    bool includeArchived = false,
    String? productId,
  }) {
    final controller = StreamController<List<Customer>>();

    var queryBuilder = _client
        .from(DatabaseConstants.customersTable)
        .stream(primaryKey: ['id']);

    if (!includeArchived) {
      queryBuilder = queryBuilder.eq('is_archived', false);
    }

    if (productId != null) {
      queryBuilder = queryBuilder.eq('product_id', productId);
    }

    _subscription =
        queryBuilder.order('created_at', ascending: false).listen((data) {
      final customers = data.map((json) => Customer.fromJson(json)).toList();
      controller.add(customers);
    });

    return controller.stream;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
