import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/domain/models/realtime_event.dart';
import 'package:app/presentation/providers/realtime_provider.dart';

class RealtimeStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final double size;

  const RealtimeStatusIndicator({
    Key? key,
    this.showLabel = true,
    this.size = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(realtimeConnectionStatusProvider);

    final (color, label) = switch (connectionStatus) {
      RealtimeConnectionStatus.connected => (Colors.green, 'Live'),
      RealtimeConnectionStatus.connecting => (Colors.orange, 'Connecting'),
      RealtimeConnectionStatus.reconnecting => (Colors.amber, 'Reconnecting'),
      RealtimeConnectionStatus.disconnected => (Colors.grey, 'Offline'),
      RealtimeConnectionStatus.error => (Colors.red, 'Error'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

class RealtimeConnectionBanner extends ConsumerWidget {
  const RealtimeConnectionBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(realtimeConnectionStatusProvider);

    if (connectionStatus == RealtimeConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final (backgroundColor, textColor, message) = switch (connectionStatus) {
      RealtimeConnectionStatus.connecting => (
        Colors.orange[50],
        Colors.orange[900],
        'Connecting to live updates...'
      ),
      RealtimeConnectionStatus.reconnecting => (
        Colors.amber[50],
        Colors.amber[900],
        'Reconnecting to live updates...'
      ),
      RealtimeConnectionStatus.disconnected => (
        Colors.grey[200],
        Colors.grey[800],
        'Live updates are offline. Changes will sync when reconnected.'
      ),
      RealtimeConnectionStatus.error => (
        Colors.red[50],
        Colors.red[900],
        'Error with live updates. Some changes may not sync immediately.'
      ),
      RealtimeConnectionStatus.connected => (null, null, ''),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          RealtimeStatusIndicator(showLabel: false, size: 6),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveUpdateIndicator extends ConsumerWidget {
  final Duration duration;

  const LiveUpdateIndicator({
    Key? key,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(realtimeConnectionStatusProvider);

    if (connectionStatus != RealtimeConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'This item was just updated',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[300]!, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Live update',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
