# Realtime Sync Implementation Guide

## Overview

This document describes the realtime synchronization system built with Supabase Realtime channels and Riverpod state management for the Flutter application. The system provides live updates for core CRM and ticketing tables with minimal UI jank and seamless fallback behavior.

## Architecture

### Core Components

#### 1. **RealtimeChannelManager** (`lib/data/services/realtime_channel_manager.dart`)

Manages the lifecycle of Supabase realtime channels with automatic reconnection.

**Key Features:**
- Automatic channel creation and subscription
- Exponential backoff reconnection (max 5 attempts)
- Multiple callbacks per table subscription
- Channel cleanup and disposal

**Usage:**
```dart
final manager = RealtimeChannelManager(supabaseClient: client);

await manager.subscribe(
  table: 'products',
  onEvent: (data) {
    print('Received event: $data');
  },
);

await manager.unsubscribe(table: 'products');
await manager.closeAll();
```

#### 2. **RealtimeEventDispatcher** (`lib/data/services/realtime_event_dispatcher.dart`)

Provides a pub-sub system for typed events with error handling.

**Key Features:**
- Type-safe event registration
- Multiple handlers per channel
- Automatic event type parsing
- Error isolation between handlers

**Usage:**
```dart
final dispatcher = RealtimeEventDispatcher();

dispatcher.on<Product>('products', (event) {
  if (event.type == RealtimeEventType.insert) {
    print('New product: ${event.data.name}');
  }
});

dispatcher.emit(RealtimeEvent<Product>(
  type: RealtimeEventType.insert,
  data: product,
  table: 'products',
));
```

#### 3. **Repository Layer**

Two repositories handle table-specific realtime events:

**CrmRealtimeRepository** (`lib/data/repositories/crm_realtime_repository.dart`)
- Manages: `products`, `customers`, `acquisitions`, `interactions`
- Converts raw events to typed domain models
- Handles event mapping and error cases

**TicketingRealtimeRepository** (`lib/data/repositories/ticketing_realtime_repository.dart`)
- Manages: `tickets`, `comments`, `attachments`
- Type-safe event emission
- Consistent error handling

### Riverpod Integration

#### Providers Structure

```
realtimeChannelManagerProvider
    ↓
realtimeEventDispatcherProvider
    ↓
├─ crmRealtimeRepositoryProvider
│   ├─ productEventsProvider (StreamProvider)
│   ├─ customerEventsProvider (StreamProvider)
│   ├─ acquisitionEventsProvider (StreamProvider)
│   └─ interactionEventsProvider (StreamProvider)
│
└─ ticketingRealtimeRepositoryProvider
    ├─ ticketEventsProvider (StreamProvider)
    ├─ commentEventsProvider (StreamProvider)
    └─ attachmentEventsProvider (StreamProvider)

realtimeConnectionStatusProvider (StateNotifierProvider)
realtimeSetupProvider (FutureProvider) - Initialization
```

#### Connection Status States

```dart
enum RealtimeConnectionStatus {
  disconnected,    // No connection
  connecting,      // Attempting to establish connection
  connected,       // Successfully connected
  error,           // Error occurred
  reconnecting,    // Attempting to reconnect after failure
}
```

## Data Models

### Core Entities

**CRM Models** (`lib/domain/models/crm_entities.dart`)
- `Product`: Represents a product with price and metadata
- `Customer`: Customer information with contact details
- `Acquisition`: Records of product purchases by customers
- `Interaction`: Customer interaction logs

**Ticketing Models** (`lib/domain/models/ticketing_entities.dart`)
- `Ticket`: Support tickets with status and priority
- `Comment`: Comments on tickets
- `Attachment`: File attachments to tickets and comments

**Realtime Models** (`lib/domain/models/realtime_event.dart`)
- `RealtimeEvent<T>`: Generic wrapper for any realtime event
- `RealtimeEventType`: Enum for insert, update, delete
- `RealtimeConnectionStatus`: Connection state tracking

## UI Components

### Realtime Status Indicators

**RealtimeStatusIndicator** - Visual indicator of connection status
```dart
RealtimeStatusIndicator(
  showLabel: true,
  size: 8.0,
)
```

**RealtimeConnectionBanner** - Informational banner for offline/error states
```dart
const RealtimeConnectionBanner()
```

**LiveUpdateIndicator** - Shows when an item was recently updated
```dart
const LiveUpdateIndicator()
```

## Integration Examples

### CRM Screen Integration

```dart
class CRMScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(realtimeConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RealtimeStatusIndicator(showLabel: true),
          ),
        ],
      ),
      body: Column(
        children: [
          const RealtimeConnectionBanner(),
          // Content with live updates
        ],
      ),
    );
  }
}
```

### Listening to Product Updates

```dart
class ProductListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productEvents = ref.watch(productEventsProvider);

    return productEvents.when(
      data: (event) {
        // Handle individual events as they arrive
        if (event.type == RealtimeEventType.insert) {
          // Update UI with new product
        }
        return SizedBox.shrink();
      },
      loading: () => CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

### Building Realtime Lists (Minimal UI Jank)

```dart
class RealtimeProductList extends ConsumerStatefulWidget {
  @override
  ConsumerState<RealtimeProductList> createState() => _RealtimeProductListState();
}

class _RealtimeProductListState extends ConsumerState<RealtimeProductList> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    // Load initial data from cache or API
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productEvents = ref.watch(productEventsProvider);

    return productEvents.when(
      data: (event) {
        _handleProductUpdate(event);
        return _buildList();
      },
      loading: () => _buildList(),
      error: (err, st) => _buildList(),
    );
  }

  void _handleProductUpdate(RealtimeEvent<Product> event) {
    setState(() {
      switch (event.type) {
        case RealtimeEventType.insert:
          if (!products.any((p) => p.id == event.data.id)) {
            products.add(event.data);
          }
        case RealtimeEventType.update:
          final index = products.indexWhere((p) => p.id == event.data.id);
          if (index >= 0) {
            products[index] = event.data;
          }
        case RealtimeEventType.delete:
          products.removeWhere((p) => p.id == event.data.id);
      }
    });
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductTile(product: product);
      },
    );
  }
}
```

## Extending for New Modules

### Step 1: Create Domain Models

Create typed models in `lib/domain/models/`:

```dart
// lib/domain/models/example_entities.dart
class ExampleEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExampleEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  ExampleEntity copyWith({...}) => ExampleEntity(...);
}
```

### Step 2: Create Repository

Create repository in `lib/data/repositories/`:

```dart
// lib/data/repositories/example_realtime_repository.dart
class ExampleRealtimeRepository {
  final RealtimeChannelManager channelManager;
  final RealtimeEventDispatcher eventDispatcher;

  ExampleRealtimeRepository({
    required this.channelManager,
    required this.eventDispatcher,
  });

  Future<void> subscribeToExamples() async {
    await channelManager.subscribe(
      table: 'examples',
      onEvent: (data) => _handleExampleEvent(data),
    );
  }

  void _handleExampleEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'examples',
    );

    try {
      final example = _mapToExample(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<ExampleEntity>(
        type: event.type,
        data: example,
        table: 'examples',
      ));
    } catch (e) {
      print('Error handling example event: $e');
    }
  }

  ExampleEntity _mapToExample(Map<String, dynamic> data) {
    return ExampleEntity(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
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
    await channelManager.unsubscribe(table: 'examples');
  }
}
```

### Step 3: Add Riverpod Providers

Update `lib/presentation/providers/realtime_provider.dart`:

```dart
final exampleRealtimeRepositoryProvider = Provider<ExampleRealtimeRepository>((ref) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  return ExampleRealtimeRepository(
    channelManager: channelManager,
    eventDispatcher: dispatcher,
  );
});
```

### Step 4: Create Event Stream Provider

Create `lib/presentation/providers/example_events_provider.dart`:

```dart
final exampleEventsProvider = StreamProvider<RealtimeEvent<ExampleEntity>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final repo = ref.watch(exampleRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<ExampleEntity>>();

  dispatcher.on<ExampleEntity>('examples', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await repo.subscribeToExamples();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('examples');
  });

  yield* controller.stream;
});
```

### Step 5: Add to Initialization

Update `RealtimeInitializationNotifier.initialize()` in `realtime_provider.dart`:

```dart
Future<void> initialize() async {
  // ... existing code ...
  
  final exampleRepo = ref.read(exampleRealtimeRepositoryProvider);
  
  await Future.wait([
    // ... existing subscriptions ...
    exampleRepo.subscribeToExamples(),
  ]);
}
```

## Error Handling and Fallbacks

### Connection Loss Handling

When the realtime connection is lost:

1. **RealtimeConnectionStatus** changes to `disconnected` or `error`
2. **RealtimeConnectionBanner** displays to inform users
3. UI gracefully degrades - existing data remains visible
4. Updates are queued and synced when reconnected

### Automatic Reconnection

The `RealtimeChannelManager` automatically attempts reconnection with exponential backoff:
- Attempt 1: 2 seconds
- Attempt 2: 4 seconds
- Attempt 3: 8 seconds
- Attempt 4: 16 seconds
- Attempt 5: 32 seconds

After 5 failed attempts, the channel stops attempting reconnection.

### Error Boundaries

Each event handler is wrapped in a try-catch to prevent one error from affecting others:

```dart
for (final callback in callbacks) {
  try {
    callback(eventData);
  } catch (e) {
    print('Error in event handler: $e');
  }
}
```

## Testing

### Unit Tests

Located in `test/realtime/`:

- `realtime_channel_manager_test.dart`: Tests for channel lifecycle
- `realtime_event_dispatcher_test.dart`: Tests for event dispatching

Run tests:
```bash
flutter test test/realtime/
```

### Integration Testing

For integration tests with a live Supabase instance:

1. Set up test database with sample tables
2. Use `mockito` for mocking Supabase client
3. Test event emission and handling
4. Verify state updates in Riverpod

Example:
```dart
test('handles product insert event', () async {
  final event = RealtimeEvent<Product>(
    type: RealtimeEventType.insert,
    data: testProduct,
    table: 'products',
  );

  dispatcher.emit(event);

  await Future.delayed(Duration(milliseconds: 100));
  expect(handlerCalled, true);
  expect(lastEventData, testProduct);
});
```

## Performance Considerations

### Minimal UI Jank

1. **Event Streaming**: Uses `StreamProvider` to emit events individually
2. **Diff Updates**: Only update changed items in lists, not entire list
3. **Async Processing**: Event handlers are processed asynchronously
4. **Callback Isolation**: Multiple handlers don't block each other

### Memory Management

1. **Channel Cleanup**: Channels are properly closed on disposal
2. **Stream Closure**: StreamControllers are closed when providers are disposed
3. **Handler Removal**: Handlers can be explicitly removed with `off()`

### Reconnection Strategy

- Exponential backoff prevents server overload
- Maximum 5 attempts before giving up (configurable)
- Status updates keep UI informed of connection state

## Troubleshooting

### Issues with Realtime Not Connecting

1. Verify Supabase API key has realtime permissions
2. Check that tables have RLS policies allowing subscriptions
3. Ensure user is authenticated before initializing realtime
4. Check network connectivity

### Events Not Received

1. Verify table name matches exactly (case-sensitive)
2. Ensure RLS policies allow read access to user
3. Check that `RealtimeConnectionBanner` shows "Connected"
4. Review logs for event handler errors

### High CPU Usage

1. Consider throttling rapid updates
2. Use diff updates instead of full list rebuilds
3. Profile with Dart DevTools
4. Check for circular subscriptions

## Security

- Realtime subscriptions respect Supabase RLS policies
- Users can only receive events for data they have access to
- Consider additional filtering based on user roles
- Always validate received data before using it

## Future Enhancements

1. **Offline Queue**: Queue mutations when offline, sync on reconnect
2. **Event Throttling**: Throttle rapid updates to prevent UI flooding
3. **Smart Caching**: Cache strategy for initial load optimization
4. **Presence**: Track user presence and active edits
5. **Conflict Resolution**: Handle concurrent updates intelligently
