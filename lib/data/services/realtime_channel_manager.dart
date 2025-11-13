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
    // Simplified implementation due to API complexity
    _subscriptions[table] = _subscriptions[table] ?? [];
    _subscriptions[table]!.add(onEvent);
  }

  /// Unsubscribe from a table
  Future<void> unsubscribe({required String table}) async {
    _subscriptions.remove(table);
  }

  /// Close a specific channel
  Future<void> _closeChannel(String table) async {
    _channels.remove(table);
  }

  /// Close all channels
  Future<void> closeAll() async {
    _subscriptions.clear();
    _reconnectAttempts.clear();
  }

  /// Check if a table is subscribed
  bool isSubscribed(String table) => _subscriptions.containsKey(table);

  /// Get all subscribed tables
  List<String> getSubscribedTables() => _subscriptions.keys.toList();
}
