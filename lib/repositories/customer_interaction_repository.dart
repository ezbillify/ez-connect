import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/database_constants.dart';
import '../core/errors/app_error.dart';
import '../core/utils/result.dart';
import '../models/customer_interaction.dart';

class CustomerInteractionRepository {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  CustomerInteractionRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<Result<List<CustomerInteraction>>> getInteractionsByCustomerId(String customerId) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customerInteractionsTable)
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final interactions = (response as List)
          .map((json) => CustomerInteraction.fromJson(json))
          .toList();

      return Success(interactions);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to fetch interactions', e));
    }
  }

  Future<Result<CustomerInteraction>> createInteraction(CustomerInteraction interaction) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customerInteractionsTable)
          .insert(interaction.toJson())
          .select()
          .single();

      return Success(CustomerInteraction.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to create interaction', e));
    }
  }

  Future<Result<CustomerInteraction>> updateInteraction(CustomerInteraction interaction) async {
    try {
      final response = await _client
          .from(DatabaseConstants.customerInteractionsTable)
          .update(interaction.toJson())
          .eq('id', interaction.id)
          .select()
          .single();

      return Success(CustomerInteraction.fromJson(response));
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to update interaction', e));
    }
  }

  Future<Result<void>> deleteInteraction(String id) async {
    try {
      await _client
          .from(DatabaseConstants.customerInteractionsTable)
          .delete()
          .eq('id', id);

      return const Success(null);
    } on SocketException {
      return const Failure(NetworkError());
    } on PostgrestException catch (e) {
      return Failure(DatabaseError(e.message, e));
    } catch (e) {
      return Failure(DatabaseError('Failed to delete interaction', e));
    }
  }

  Stream<List<CustomerInteraction>> watchInteractions(String customerId) {
    final controller = StreamController<List<CustomerInteraction>>();

    _subscription = _client
        .from(DatabaseConstants.customerInteractionsTable)
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .listen((data) {
          final interactions = data.map((json) => CustomerInteraction.fromJson(json)).toList();
          controller.add(interactions);
        });

    return controller.stream;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
