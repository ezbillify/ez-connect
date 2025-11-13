import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/services/realtime_event_dispatcher.dart';
import 'package:app/domain/models/realtime_event.dart';

void main() {
  group('RealtimeEventDispatcher', () {
    late RealtimeEventDispatcher dispatcher;

    setUp(() {
      dispatcher = RealtimeEventDispatcher();
    });

    test('handler is called when event is emitted', () {
      bool handlerCalled = false;
      dispatcher.on<Map<String, dynamic>>('products', (event) {
        handlerCalled = true;
      });

      final event = RealtimeEvent<Map<String, dynamic>>(
        type: RealtimeEventType.insert,
        data: {'id': '1', 'name': 'Product'},
        table: 'products',
      );

      dispatcher.emit(event);

      expect(handlerCalled, true);
    });

    test('handler is not called for different table', () {
      bool handlerCalled = false;
      dispatcher.on<Map<String, dynamic>>('products', (event) {
        handlerCalled = true;
      });

      final event = RealtimeEvent<Map<String, dynamic>>(
        type: RealtimeEventType.insert,
        data: {'id': '1'},
        table: 'customers',
      );

      dispatcher.emit(event);

      expect(handlerCalled, false);
    });

    test('parseEvent correctly parses insert event', () {
      final event = RealtimeEventDispatcher.parseEvent(
        rawData: {
          'type': 'insert',
          'new': {'id': '1', 'name': 'Product'},
        },
        table: 'products',
      );

      expect(event.type, RealtimeEventType.insert);
      expect(event.table, 'products');
      expect(event.data['id'], '1');
    });

    test('parseEvent correctly parses delete event', () {
      final event = RealtimeEventDispatcher.parseEvent(
        rawData: {
          'type': 'delete',
          'old': {'id': '1'},
        },
        table: 'products',
      );

      expect(event.type, RealtimeEventType.delete);
    });

    test('clearChannel removes all handlers for channel', () {
      bool handlerCalled = false;
      dispatcher.on<Map<String, dynamic>>('products', (event) {
        handlerCalled = true;
      });

      dispatcher.clearChannel('products');

      final event = RealtimeEvent<Map<String, dynamic>>(
        type: RealtimeEventType.insert,
        data: {},
        table: 'products',
      );

      dispatcher.emit(event);

      expect(handlerCalled, false);
    });

    test('multiple handlers are called for same event', () {
      int callCount = 0;
      dispatcher.on<Map<String, dynamic>>('products', (event) {
        callCount++;
      });
      dispatcher.on<Map<String, dynamic>>('products', (event) {
        callCount++;
      });

      final event = RealtimeEvent<Map<String, dynamic>>(
        type: RealtimeEventType.insert,
        data: {},
        table: 'products',
      );

      dispatcher.emit(event);

      expect(callCount, 2);
    });
  });
}
