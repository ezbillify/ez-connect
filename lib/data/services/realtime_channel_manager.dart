import 'package:supabase_flutter/supabase_flutter.dart';

typedef RealtimeEventCallback = Function(Map<String, dynamic>);

class RealtimeChannelManager {
  final SupabaseClient supabaseClient;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, List<RealtimeEventCallback>> _subscriptions = {};
  final Map<String, int> _reconnectAttempts = {};
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  RealtimeChannelManager({required this.supabaseClient});

  /// Subscribe to a table with automatic reconnection
  Future<void> subscribe({
    required String table,
    required RealtimeEventCallback onEvent,
    String? filter,
  }) async {
    if (_channels.containsKey(table)) {
      _subscriptions[table]?.add(onEvent);
      return;
    }

    _subscriptions[table] = [onEvent];
    _reconnectAttempts[table] = 0;

    await _createChannel(table, filter: filter);
  }

  /// Unsubscribe from a table
  Future<void> unsubscribe({required String table}) async {
    _subscriptions.remove(table);
    await _closeChannel(table);
  }

  /// Create and open a channel
  Future<void> _createChannel(String table, {String? filter}) async {
    try {
      final channel = supabaseClient.channel('${table}_changes').onPostgresChanges(
            event: '*',
            schema: 'public',
            table: table,
            filter: filter,
            callback: (payload) {
              _handleEvent(table, payload);
            },
          );

      await channel.subscribe();
      _channels[table] = channel;
      _reconnectAttempts[table] = 0;
    } catch (e) {
      print('Error creating channel for $table: $e');
      await _handleReconnection(table);
    }
  }

  /// Handle incoming events
  void _handleEvent(String table, PostgresChangePayload payload) {
    final callbacks = _subscriptions[table];
    if (callbacks != null) {
      final eventData = {
        'type': payload.eventType.toString().split('.').last.toLowerCase(),
        'new': payload.newRecord,
        'old': payload.oldRecord,
        'table': table,
      };
      for (final callback in callbacks) {
        callback(eventData);
      }
    }
  }

  /// Handle reconnection with exponential backoff
  Future<void> _handleReconnection(String table) async {
    int attempts = _reconnectAttempts[table] ?? 0;
    if (attempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached for $table');
      return;
    }

    attempts++;
    _reconnectAttempts[table] = attempts;

    final delay = _reconnectDelay * (1 << (attempts - 1));
    print('Reconnecting to $table in ${delay.inSeconds}s (attempt $attempts/$_maxReconnectAttempts)');

    await Future.delayed(delay);
    await _createChannel(table);
  }

  /// Close a specific channel
  Future<void> _closeChannel(String table) async {
    final channel = _channels[table];
    if (channel != null) {
      await supabaseClient.removeChannel(channel);
      _channels.remove(table);
    }
  }

  /// Close all channels
  Future<void> closeAll() async {
    final tables = _channels.keys.toList();
    for (final table in tables) {
      await _closeChannel(table);
    }
    _subscriptions.clear();
    _reconnectAttempts.clear();
  }

  /// Check if a table is subscribed
  bool isSubscribed(String table) => _channels.containsKey(table);

  /// Get all subscribed tables
  List<String> getSubscribedTables() => _channels.keys.toList();
}
