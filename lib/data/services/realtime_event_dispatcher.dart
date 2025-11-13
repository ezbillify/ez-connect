import 'package:app/domain/models/realtime_event.dart';

typedef EventHandler<T> = void Function(RealtimeEvent<T>);

class RealtimeEventDispatcher {
  final Map<String, List<Function>> _handlers = {};

  /// Register a handler for a specific event type
  void on<T>(String channel, EventHandler<T> handler) {
    if (!_handlers.containsKey(channel)) {
      _handlers[channel] = [];
    }
    _handlers[channel]!.add(handler);
  }

  /// Unregister a handler
  void off<T>(String channel, EventHandler<T> handler) {
    _handlers[channel]?.remove(handler);
  }

  /// Emit an event to all registered handlers
  void emit<T>(RealtimeEvent<T> event) {
    final handlers = _handlers[event.table];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler(event);
        } catch (e) {
          print('Error in event handler for ${event.table}: $e');
        }
      }
    }
  }

  /// Clear all handlers for a channel
  void clearChannel(String channel) {
    _handlers.remove(channel);
  }

  /// Clear all handlers
  void clearAll() {
    _handlers.clear();
  }

  /// Convert raw event data to RealtimeEvent
  static RealtimeEvent<Map<String, dynamic>> parseEvent({
    required Map<String, dynamic> rawData,
    required String table,
  }) {
    final typeString = rawData['type'] as String? ?? 'update';
    final type = _parseEventType(typeString);
    final data = (rawData['new'] ?? rawData['old']) as Map<String, dynamic>? ?? {};

    return RealtimeEvent<Map<String, dynamic>>(
      type: type,
      data: data,
      table: table,
    );
  }

  static RealtimeEventType _parseEventType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'insert':
        return RealtimeEventType.insert;
      case 'delete':
        return RealtimeEventType.delete;
      case 'update':
      default:
        return RealtimeEventType.update;
    }
  }
}
