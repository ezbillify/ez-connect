# Realtime Sync Quick Start

## What's Included

This implementation provides a complete realtime synchronization system for the Flutter app using Supabase Realtime channels.

### Features

✅ Real-time channel subscriptions for 7 core tables:
- CRM: products, customers, acquisitions, interactions
- Ticketing: tickets, comments, attachments

✅ Automatic reconnection with exponential backoff

✅ Type-safe event handling with Riverpod

✅ Visual connection status indicators

✅ Minimal UI jank through event streaming

✅ Error handling and fallbacks

✅ Comprehensive tests and documentation

## Quick Start

### 1. The system initializes automatically

When your app starts, realtime subscriptions are set up automatically:

```dart
// In main.dart, the realtimeSetupProvider initializes everything
ref.watch(realtimeSetupProvider);
```

### 2. Use realtime data in your UI

Watch for product updates:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productEvents = ref.watch(productEventsProvider);
    
    return productEvents.when(
      data: (event) {
        // Handle individual product event
        print('${event.type}: ${event.data.id}');
        return SizedBox.shrink();
      },
      loading: () => CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

### 3. Show connection status to users

Display a status indicator:

```dart
RealtimeStatusIndicator(showLabel: true) // Shows green dot when connected
```

Show connection banner:

```dart
const RealtimeConnectionBanner() // Informs user when offline
```

## Available Event Streams

**CRM Events** (import: `crm_events_provider.dart`):
- `productEventsProvider`
- `customerEventsProvider`
- `acquisitionEventsProvider`
- `interactionEventsProvider`

**Ticketing Events** (import: `ticketing_events_provider.dart`):
- `ticketEventsProvider`
- `commentEventsProvider`
- `attachmentEventsProvider`

Each returns `StreamProvider<RealtimeEvent<T>>` where T is the entity type.

## Working with Events

Events have three types:

```dart
enum RealtimeEventType {
  insert,   // New item created
  update,   // Existing item changed
  delete,   // Item deleted
}
```

Handle events in your UI:

```dart
final productEvents = ref.watch(productEventsProvider);

productEvents.whenData((event) {
  switch (event.type) {
    case RealtimeEventType.insert:
      print('New product: ${event.data.name}');
    case RealtimeEventType.update:
      print('Updated product: ${event.data.name}');
    case RealtimeEventType.delete:
      print('Deleted product: ${event.data.id}');
  }
});
```

## Connection Status

Monitor connection status:

```dart
final status = ref.watch(realtimeConnectionStatusProvider);

final isConnected = status == RealtimeConnectionStatus.connected;
```

States:
- `connected` - Live updates working
- `connecting` - Establishing connection
- `reconnecting` - Attempting to reconnect
- `disconnected` - No connection
- `error` - Connection error

## Minimal UI Jank Implementation

Instead of rebuilding entire lists, update individual items:

```dart
class ProductList extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProductList> createState() => _ProductListState();
}

class _ProductListState extends ConsumerState<ProductList> {
  List<Product> products = [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(productEventsProvider);
    
    return events.whenData((event) {
      _updateLocalList(event);
      return _buildList();
    });
  }

  void _updateLocalList(RealtimeEvent<Product> event) {
    setState(() {
      if (event.type == RealtimeEventType.insert) {
        products.add(event.data);
      } else if (event.type == RealtimeEventType.update) {
        final index = products.indexWhere((p) => p.id == event.data.id);
        if (index >= 0) products[index] = event.data;
      } else if (event.type == RealtimeEventType.delete) {
        products.removeWhere((p) => p.id == event.data.id);
      }
    });
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, i) => ProductTile(product: products[i]),
    );
  }
}
```

## Testing

Run tests:

```bash
# Unit tests
flutter test test/realtime/

# Integration tests
flutter test test/integration/
```

## Adding Realtime to New Tables

See `docs/REALTIME_SYNC.md` "Extending for New Modules" section for step-by-step guide.

## Troubleshooting

### Events not receiving?

1. Check `RealtimeConnectionBanner` - is it showing "Connected"?
2. Verify you're authenticated (check `isAuthenticatedProvider`)
3. Check Supabase RLS policies allow reads
4. Review logs for errors

### Connection keeps dropping?

1. Check network stability
2. Verify Supabase project is running
3. Check API key in .env file

### UI freezing on updates?

1. Don't rebuild entire screens on events
2. Update local state instead
3. Use diff updates for lists (see example above)

## File Structure

```
lib/
├── data/
│   ├── services/
│   │   ├── realtime_channel_manager.dart
│   │   └── realtime_event_dispatcher.dart
│   └── repositories/
│       ├── crm_realtime_repository.dart
│       └── ticketing_realtime_repository.dart
├── domain/models/
│   ├── realtime_event.dart
│   ├── crm_entities.dart
│   └── ticketing_entities.dart
├── presentation/
│   ├── providers/
│   │   ├── realtime_provider.dart
│   │   ├── crm_events_provider.dart
│   │   └── ticketing_events_provider.dart
│   └── screens/
│       ├── crm/crm_screen.dart (updated)
│       └── ticketing/ticketing_screen.dart (updated)
└── shared/widgets/
    └── realtime_status_indicator.dart

test/
├── realtime/
│   ├── realtime_channel_manager_test.dart
│   └── realtime_event_dispatcher_test.dart
└── integration/
    └── realtime_integration_test.dart

docs/
├── REALTIME_SYNC.md (full documentation)
├── REALTIME_IMPLEMENTATION_GUIDE.md (technical details)
└── REALTIME_QUICKSTART.md (this file)
```

## Key Concepts

### Channel Manager
Manages Supabase realtime channel lifecycle, subscriptions, and reconnection logic.

### Event Dispatcher
Pub-sub system for emitting typed events to multiple listeners.

### Repositories
Map raw events to domain models (Product, Ticket, etc.).

### Riverpod Providers
State management and dependency injection for clean architecture.

### Stream Providers
Emit events as streams for reactive UI updates.

## Performance

- **One channel per table** - Efficient connection usage
- **Event streaming** - Not batching, immediate UI responsiveness
- **Exponential backoff** - Smart reconnection strategy
- **Error isolation** - One handler error doesn't affect others
- **Automatic cleanup** - Proper disposal on widget unmount

## Next Steps

1. Review `docs/REALTIME_SYNC.md` for complete documentation
2. Check CRM and Ticketing screens for integration example
3. Run tests to verify setup
4. Add realtime features to your UI components

## Support

For detailed information:
- Architecture: `docs/REALTIME_IMPLEMENTATION_GUIDE.md`
- API Reference: `docs/REALTIME_SYNC.md`
- Examples: CRM and Ticketing screens in `lib/presentation/screens/`
- Tests: `test/` directory
