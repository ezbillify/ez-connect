import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/services/realtime_channel_manager.dart';
import 'package:app/data/services/realtime_event_dispatcher.dart';
import 'package:app/domain/models/crm_entities.dart';
import 'package:app/domain/models/realtime_event.dart';

void main() {
  group('Realtime Integration Tests', () {
    late RealtimeEventDispatcher dispatcher;

    setUp(() {
      dispatcher = RealtimeEventDispatcher();
    });

    test('Product event flow: insert -> update -> delete', () async {
      final events = <RealtimeEvent<Product>>[];

      dispatcher.on<Product>('products', (event) {
        events.add(event);
      });

      final product1 = Product(
        id: 'prod-1',
        name: 'Test Product',
        price: 99.99,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product1,
        table: 'products',
      ));

      final updatedProduct = product1.copyWith(name: 'Updated Product');
      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.update,
        data: updatedProduct,
        table: 'products',
      ));

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.delete,
        data: product1,
        table: 'products',
      ));

      expect(events.length, 3);
      expect(events[0].type, RealtimeEventType.insert);
      expect(events[1].type, RealtimeEventType.update);
      expect(events[1].data.name, 'Updated Product');
      expect(events[2].type, RealtimeEventType.delete);
    });

    test('Multiple table subscriptions work independently', () async {
      final productEvents = <RealtimeEvent<Product>>[];
      final customerEvents = <RealtimeEvent<Customer>>[];

      dispatcher.on<Product>('products', (event) {
        productEvents.add(event);
      });

      dispatcher.on<Customer>('customers', (event) {
        customerEvents.add(event);
      });

      final product = Product(
        id: 'prod-1',
        name: 'Product',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customer = Customer(
        id: 'cust-1',
        name: 'Customer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product,
        table: 'products',
      ));

      dispatcher.emit(RealtimeEvent<Customer>(
        type: RealtimeEventType.insert,
        data: customer,
        table: 'customers',
      ));

      expect(productEvents.length, 1);
      expect(customerEvents.length, 1);
      expect(productEvents.first.table, 'products');
      expect(customerEvents.first.table, 'customers');
    });

    test('Event handler errors do not affect other handlers', () async {
      bool handler1Called = false;
      bool handler2Called = false;

      dispatcher.on<Product>('products', (event) {
        handler1Called = true;
        throw Exception('Handler 1 error');
      });

      dispatcher.on<Product>('products', (event) {
        handler2Called = true;
      });

      final product = Product(
        id: 'prod-1',
        name: 'Product',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product,
        table: 'products',
      ));

      expect(handler1Called, true);
      expect(handler2Called, true);
    });

    test('Event type parsing handles all event types', () {
      final insertEvent = RealtimeEventDispatcher.parseEvent(
        rawData: {'type': 'insert', 'new': {}},
        table: 'products',
      );

      final updateEvent = RealtimeEventDispatcher.parseEvent(
        rawData: {'type': 'update', 'new': {}},
        table: 'products',
      );

      final deleteEvent = RealtimeEventDispatcher.parseEvent(
        rawData: {'type': 'delete', 'old': {}},
        table: 'products',
      );

      expect(insertEvent.type, RealtimeEventType.insert);
      expect(updateEvent.type, RealtimeEventType.update);
      expect(deleteEvent.type, RealtimeEventType.delete);
    });

    test('clearChannel removes all handlers', () async {
      int callCount = 0;

      dispatcher.on<Product>('products', (event) {
        callCount++;
      });

      final product = Product(
        id: 'prod-1',
        name: 'Product',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product,
        table: 'products',
      ));

      dispatcher.clearChannel('products');

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product,
        table: 'products',
      ));

      expect(callCount, 1);
    });

    test('clearAll removes all handlers from all channels', () async {
      int productCallCount = 0;
      int customerCallCount = 0;

      dispatcher.on<Product>('products', (event) {
        productCallCount++;
      });

      dispatcher.on<Customer>('customers', (event) {
        customerCallCount++;
      });

      final product = Product(
        id: 'prod-1',
        name: 'Product',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customer = Customer(
        id: 'cust-1',
        name: 'Customer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      dispatcher.clearAll();

      dispatcher.emit(RealtimeEvent<Product>(
        type: RealtimeEventType.insert,
        data: product,
        table: 'products',
      ));

      dispatcher.emit(RealtimeEvent<Customer>(
        type: RealtimeEventType.insert,
        data: customer,
        table: 'customers',
      ));

      expect(productCallCount, 0);
      expect(customerCallCount, 0);
    });
  });
}
