# Realtime Sync Implementation Details

## Project Structure

```
lib/
├── data/
│   ├── services/
│   │   ├── realtime_channel_manager.dart          # Channel lifecycle management
│   │   └── realtime_event_dispatcher.dart         # Event pub-sub system
│   └── repositories/
│       ├── crm_realtime_repository.dart           # CRM table subscriptions
│       └── ticketing_realtime_repository.dart     # Ticketing table subscriptions
├── domain/
│   └── models/
│       ├── realtime_event.dart                    # Event & status types
│       ├── crm_entities.dart                      # Product, Customer, etc.
│       └── ticketing_entities.dart                # Ticket, Comment, Attachment
├── presentation/
│   ├── providers/
│   │   ├── realtime_provider.dart                 # Core Riverpod providers
│   │   ├── crm_events_provider.dart               # CRM event streams
│   │   └── ticketing_events_provider.dart         # Ticketing event streams
│   └── screens/
│       ├── crm/
│       │   └── crm_screen.dart                    # Updated with realtime UI
│       └── ticketing/
│           └── ticketing_screen.dart              # Updated with realtime UI
└── shared/
    └── widgets/
        └── realtime_status_indicator.dart         # Connection status widgets

test/
├── realtime/
│   ├── realtime_channel_manager_test.dart         # Unit tests
│   └── realtime_event_dispatcher_test.dart        # Event dispatcher tests
└── integration/
    └── realtime_integration_test.dart             # Integration tests

docs/
├── REALTIME_SYNC.md                              # Main documentation
└── REALTIME_IMPLEMENTATION_GUIDE.md              # This file
```

## Key Features Implemented

### 1. Channel Lifecycle Management

**File**: `lib/data/services/realtime_channel_manager.dart`

- **Subscription**: Creates Supabase realtime channels for tables
- **Reconnection**: Automatic exponential backoff reconnection (2s → 4s → 8s → 16s → 32s)
- **Multiple Callbacks**: Support multiple event handlers per table
- **Cleanup**: Properly closes channels on disposal

**Key Methods**:
- `subscribe(table, onEvent, filter)` - Subscribe to table changes
- `unsubscribe(table)` - Unsubscribe from table
- `closeAll()` - Close all channels
- `isSubscribed(table)` - Check subscription status
- `getSubscribedTables()` - Get list of subscribed tables

### 2. Event Dispatching System

**File**: `lib/data/services/realtime_event_dispatcher.dart`

- **Type-Safe Events**: Generic `RealtimeEvent<T>` for any data type
- **Pub-Sub Pattern**: Register handlers, emit events
- **Error Isolation**: Errors in one handler don't affect others
- **Event Parsing**: Automatic parsing of raw Supabase events

**Key Methods**:
- `on<T>(channel, handler)` - Register event handler
- `off<T>(channel, handler)` - Unregister handler
- `emit<T>(event)` - Emit event to all handlers
- `clearChannel(table)` - Clear all handlers for table
- `parseEvent(rawData, table)` - Parse raw Supabase event

### 3. Data Models

**CRM Entities** (`lib/domain/models/crm_entities.dart`):
- `Product`: id, name, description, price, timestamps
- `Customer`: id, name, email, phone, timestamps
- `Acquisition`: id, customer_id, product_id, quantity, total_amount, timestamps
- `Interaction`: id, customer_id, type, notes, interaction_at, timestamps

**Ticketing Entities** (`lib/domain/models/ticketing_entities.dart`):
- `Ticket`: id, title, description, status, priority, customer_id, assigned_to, timestamps
- `Comment`: id, ticket_id, author_id, content, timestamps
- `Attachment`: id, ticket_id, comment_id, file_name, file_url, file_type, file_size, timestamps

**Realtime Models** (`lib/domain/models/realtime_event.dart`):
- `RealtimeEvent<T>`: type, data, table, timestamp
- `RealtimeEventType`: insert, update, delete
- `RealtimeConnectionStatus`: disconnected, connecting, connected, error, reconnecting

### 4. Repository Layer

**CRM Repository** (`lib/data/repositories/crm_realtime_repository.dart`):
- Subscribes to: products, customers, acquisitions, interactions
- Converts raw event data to typed models
- Emits events through dispatcher

**Ticketing Repository** (`lib/data/repositories/ticketing_realtime_repository.dart`):
- Subscribes to: tickets, comments, attachments
- Type-safe event emission
- Handles data mapping and errors

### 5. Riverpod State Management

**Core Providers** (`lib/presentation/providers/realtime_provider.dart`):

```dart
// Service providers
realtimeChannelManagerProvider       // RealtimeChannelManager
realtimeEventDispatcherProvider      // RealtimeEventDispatcher

// Repository providers
crmRealtimeRepositoryProvider        // CrmRealtimeRepository
ticketingRealtimeRepositoryProvider  // TicketingRealtimeRepository

// Connection status
realtimeConnectionStatusProvider     // StateNotifier<RealtimeConnectionStatus>

// Initialization
realtimeInitializationProvider       // StateNotifier<AsyncValue<void>>
realtimeSetupProvider                // FutureProvider - called at app startup

// Query providers
subscribedTablesProvider             // List<String>
isTableSubscribedProvider(table)     // bool - for specific table
```

**Event Stream Providers**:

CRM Events (`lib/presentation/providers/crm_events_provider.dart`):
- `productEventsProvider` - StreamProvider<RealtimeEvent<Product>>
- `customerEventsProvider` - StreamProvider<RealtimeEvent<Customer>>
- `acquisitionEventsProvider` - StreamProvider<RealtimeEvent<Acquisition>>
- `interactionEventsProvider` - StreamProvider<RealtimeEvent<Interaction>>

Ticketing Events (`lib/presentation/providers/ticketing_events_provider.dart`):
- `ticketEventsProvider` - StreamProvider<RealtimeEvent<Ticket>>
- `commentEventsProvider` - StreamProvider<RealtimeEvent<Comment>>
- `attachmentEventsProvider` - StreamProvider<RealtimeEvent<Attachment>>

### 6. UI Components

**Status Indicator** (`lib/shared/widgets/realtime_status_indicator.dart`):

- `RealtimeStatusIndicator`: Small colored dot with optional label
  - Green: Connected
  - Orange: Connecting
  - Amber: Reconnecting
  - Grey: Disconnected
  - Red: Error

- `RealtimeConnectionBanner`: Informational banner
  - Shows when not connected
  - Informs user of connection status
  - Suggests action if needed

- `LiveUpdateIndicator`: Badge for recently updated items
  - Shows only when connected
  - Indicates item was just updated from server

**Screen Integration**:
- CRM Screen: Shows status in AppBar, banner below AppBar
- Ticketing Screen: Same layout as CRM

### 7. Testing

**Unit Tests** (`test/realtime/`):

- `realtime_channel_manager_test.dart`:
  - Channel initialization
  - Subscription tracking
  - Channel cleanup

- `realtime_event_dispatcher_test.dart`:
  - Handler registration/removal
  - Event emission
  - Event type parsing
  - Error handling in handlers

**Integration Tests** (`test/integration/`):

- `realtime_integration_test.dart`:
  - Full event lifecycle (insert → update → delete)
  - Multiple table independence
  - Error isolation between handlers
  - All event types parsing
  - Channel cleanup

## How It Works

### 1. App Initialization

```
main()
  ↓
ProviderScope
  ↓
MyApp (ConsumerWidget)
  ↓
ref.watch(realtimeSetupProvider)  // Triggers initialization
  ↓
RealtimeInitializationNotifier.initialize()
  ↓
1. Check if user is authenticated
2. Subscribe to CRM tables:
   - products, customers, acquisitions, interactions
3. Subscribe to ticketing tables:
   - tickets, comments, attachments
4. Update connectionStatus to "connected"
```

### 2. Event Flow

```
Supabase Database Change
  ↓
Supabase Realtime Channel
  ↓
RealtimeChannelManager.onEvent(payload)
  ↓
Raw event callback → CrmRealtimeRepository/_handleEvent()
  ↓
Parse event → Map to domain model
  ↓
RealtimeEventDispatcher.emit(RealtimeEvent<T>)
  ↓
All registered handlers called
  ↓
StreamProvider emits event
  ↓
UI receives event via StreamProvider.watch()
  ↓
UI updates (minimal diff update)
```

### 3. Error Handling Flow

```
Error in database subscription
  ↓
RealtimeChannelManager catches error
  ↓
Attempts reconnection with exponential backoff
  ↓
After 5 failed attempts → gives up
  ↓
RealtimeConnectionStatus → error/disconnected
  ↓
RealtimeConnectionBanner shows user
  ↓
When connection restores → StreamProvider resumes
```

## Performance Optimizations

### 1. Minimal UI Jank

- **Event Streaming**: Events emit individually, not batched
- **Diff Updates**: Update only changed items in lists
- **Async Processing**: Event handlers run asynchronously
- **No Rebuild on Every Event**: Only rebuild affected widgets

### 2. Memory Management

- **Channel Cleanup**: Channels closed in `ref.onDispose()`
- **Stream Closure**: StreamControllers properly closed
- **Handler Removal**: Can explicitly call `dispatcher.off()`
- **Single Dispatcher**: One instance shared across providers

### 3. Network Efficiency

- **Single Connection**: One realtime connection per table
- **Smart Reconnection**: Exponential backoff prevents hammering
- **Efficient Payloads**: Only changed data transmitted
- **Automatic Filtering**: Can filter events per user/role

## Integration Checklist

For integrating realtime updates into a feature module:

- [ ] Create domain models (CRM or Ticketing entities)
- [ ] Create repository (subscribe to tables)
- [ ] Add Riverpod providers (channel manager, event streams)
- [ ] Create event stream provider(s)
- [ ] Add initialization to `RealtimeInitializationNotifier`
- [ ] Update UI screens with realtime widgets
- [ ] Add unit tests for event handling
- [ ] Add integration tests for full flow
- [ ] Document how to extend further

## Debugging Tips

### Check Connection Status

```dart
final status = ref.watch(realtimeConnectionStatusProvider);
print('Connection status: $status');
```

### Check Subscribed Tables

```dart
final tables = ref.watch(subscribedTablesProvider);
print('Subscribed to: $tables');
```

### Monitor Events

```dart
final productEvents = ref.watch(productEventsProvider);
productEvents.whenData((event) {
  print('Product event: ${event.type} - ${event.data.id}');
});
```

### Check for Handler Errors

Enable debug logging in `RealtimeEventDispatcher.emit()` and `RealtimeChannelManager._handleEvent()`.

## Security Considerations

1. **RLS Policies**: Supabase RLS policies control what data user receives
2. **Authentication Check**: Realtime only initializes if user authenticated
3. **Event Validation**: Always validate received data before using
4. **Role-Based Filtering**: Can add additional filtering based on user roles
5. **Sensitive Data**: Don't log or expose sensitive fields in events

## Scalability

The system is designed to scale:

- **Multiple Tables**: Each table gets its own channel
- **Large Datasets**: Events are per-item, not full table dumps
- **Many Users**: Supabase handles connection pooling
- **Custom Filters**: Can add PostgreSQL filters to reduce event volume
- **Throttling**: Can throttle rapid updates if needed

## Future Enhancements

1. **Offline Queue**: Queue mutations when offline
2. **Event Throttling**: Throttle rapid updates
3. **Presence Tracking**: Know who's editing what
4. **Conflict Resolution**: Handle concurrent edits
5. **Event History**: Maintain changelog for undo/redo
6. **Batch Operations**: Batch multiple updates
7. **Smart Caching**: Cache strategy for large datasets
