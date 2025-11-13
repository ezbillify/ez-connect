import 'package:app/data/services/realtime_channel_manager.dart';
import 'package:app/data/services/realtime_event_dispatcher.dart';
import 'package:app/domain/models/crm_entities.dart';
import 'package:app/domain/models/realtime_event.dart';

class CrmRealtimeRepository {
  final RealtimeChannelManager channelManager;
  final RealtimeEventDispatcher eventDispatcher;

  CrmRealtimeRepository({
    required this.channelManager,
    required this.eventDispatcher,
  });

  Future<void> subscribeToProducts() async {
    await channelManager.subscribe(
      table: 'products',
      onEvent: (data) => _handleProductEvent(data),
    );
  }

  Future<void> subscribeToCustomers() async {
    await channelManager.subscribe(
      table: 'customers',
      onEvent: (data) => _handleCustomerEvent(data),
    );
  }

  Future<void> subscribeToAcquisitions() async {
    await channelManager.subscribe(
      table: 'acquisitions',
      onEvent: (data) => _handleAcquisitionEvent(data),
    );
  }

  Future<void> subscribeToInteractions() async {
    await channelManager.subscribe(
      table: 'interactions',
      onEvent: (data) => _handleInteractionEvent(data),
    );
  }

  void _handleProductEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'products',
    );

    try {
      final product = _mapToProduct(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Product>(
        type: event.type,
        data: product,
        table: 'products',
      ));
    } catch (e) {
      print('Error handling product event: $e');
    }
  }

  void _handleCustomerEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'customers',
    );

    try {
      final customer = _mapToCustomer(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Customer>(
        type: event.type,
        data: customer,
        table: 'customers',
      ));
    } catch (e) {
      print('Error handling customer event: $e');
    }
  }

  void _handleAcquisitionEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'acquisitions',
    );

    try {
      final acquisition = _mapToAcquisition(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Acquisition>(
        type: event.type,
        data: acquisition,
        table: 'acquisitions',
      ));
    } catch (e) {
      print('Error handling acquisition event: $e');
    }
  }

  void _handleInteractionEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'interactions',
    );

    try {
      final interaction = _mapToInteraction(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Interaction>(
        type: event.type,
        data: interaction,
        table: 'interactions',
      ));
    } catch (e) {
      print('Error handling interaction event: $e');
    }
  }

  Product _mapToProduct(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  Customer _mapToCustomer(Map<String, dynamic> data) {
    return Customer(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  Acquisition _mapToAcquisition(Map<String, dynamic> data) {
    return Acquisition(
      id: data['id'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      productId: data['product_id'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
      acquiredAt: _parseDateTime(data['acquired_at']),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  Interaction _mapToInteraction(Map<String, dynamic> data) {
    return Interaction(
      id: data['id'] as String? ?? '',
      customerId: data['customer_id'] as String? ?? '',
      type: data['type'] as String? ?? '',
      notes: data['notes'] as String?,
      interactionAt: _parseDateTime(data['interaction_at']),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Future<void> unsubscribeFromAll() async {
    await channelManager.unsubscribe(table: 'products');
    await channelManager.unsubscribe(table: 'customers');
    await channelManager.unsubscribe(table: 'acquisitions');
    await channelManager.unsubscribe(table: 'interactions');
  }
}
