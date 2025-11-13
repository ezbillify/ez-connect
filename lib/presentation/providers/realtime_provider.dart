import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:app/data/services/realtime_channel_manager.dart';
import 'package:app/data/services/realtime_event_dispatcher.dart';
import 'package:app/data/repositories/crm_realtime_repository.dart';
import 'package:app/data/repositories/ticketing_realtime_repository.dart';
import 'package:app/domain/models/realtime_event.dart';
import 'package:app/presentation/providers/auth_provider.dart';

/// Realtime channel manager provider
final realtimeChannelManagerProvider = Provider<RealtimeChannelManager>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return RealtimeChannelManager(supabaseClient: supabase);
});

/// Realtime event dispatcher provider
final realtimeEventDispatcherProvider = Provider<RealtimeEventDispatcher>((ref) {
  return RealtimeEventDispatcher();
});

/// CRM realtime repository provider
final crmRealtimeRepositoryProvider = Provider<CrmRealtimeRepository>((ref) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  return CrmRealtimeRepository(
    channelManager: channelManager,
    eventDispatcher: dispatcher,
  );
});

/// Ticketing realtime repository provider
final ticketingRealtimeRepositoryProvider = Provider<TicketingRealtimeRepository>((ref) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  return TicketingRealtimeRepository(
    channelManager: channelManager,
    eventDispatcher: dispatcher,
  );
});

/// Realtime connection status notifier
class RealtimeConnectionNotifier extends StateNotifier<RealtimeConnectionStatus> {
  final RealtimeChannelManager channelManager;
  final Ref ref;

  RealtimeConnectionNotifier({
    required this.channelManager,
    required this.ref,
  }) : super(RealtimeConnectionStatus.disconnected);

  void connect() async {
    state = RealtimeConnectionStatus.connecting;
    try {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (!isAuthenticated) {
        state = RealtimeConnectionStatus.disconnected;
        return;
      }

      state = RealtimeConnectionStatus.connected;
    } catch (e) {
      print('Error connecting realtime: $e');
      state = RealtimeConnectionStatus.error;
    }
  }

  void disconnect() async {
    state = RealtimeConnectionStatus.disconnected;
    await channelManager.closeAll();
  }

  void setError() {
    state = RealtimeConnectionStatus.error;
  }
}

/// Realtime connection status provider
final realtimeConnectionStatusProvider =
    StateNotifierProvider<RealtimeConnectionNotifier, RealtimeConnectionStatus>((ref) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  return RealtimeConnectionNotifier(
    channelManager: channelManager,
    ref: ref,
  );
});

/// Realtime initialization notifier
class RealtimeInitializationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  RealtimeInitializationNotifier({required this.ref})
      : super(const AsyncValue.loading());

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (!isAuthenticated) {
        state = const AsyncValue.data(null);
        return;
      }

      final crmRepo = ref.read(crmRealtimeRepositoryProvider);
      final ticketingRepo = ref.read(ticketingRealtimeRepositoryProvider);
      final connectionNotifier = ref.read(realtimeConnectionStatusProvider.notifier);

      connectionNotifier.connect();

      await Future.wait([
        crmRepo.subscribeToProducts(),
        crmRepo.subscribeToCustomers(),
        crmRepo.subscribeToAcquisitions(),
        crmRepo.subscribeToInteractions(),
        ticketingRepo.subscribeToTickets(),
        ticketingRepo.subscribeToComments(),
        ticketingRepo.subscribeToAttachments(),
      ]);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      print('Error initializing realtime: $e');
      state = AsyncValue.error(e, st);
      ref.read(realtimeConnectionStatusProvider.notifier).setError();
    }
  }

  Future<void> cleanup() async {
    final channelManager = ref.read(realtimeChannelManagerProvider);
    await channelManager.closeAll();
    ref.read(realtimeConnectionStatusProvider.notifier).disconnect();
  }
}

/// Realtime initialization provider
final realtimeInitializationProvider =
    StateNotifierProvider<RealtimeInitializationNotifier, AsyncValue<void>>((ref) {
  return RealtimeInitializationNotifier(ref: ref);
});

/// Initialize realtime on app startup
final realtimeSetupProvider = FutureProvider<void>((ref) async {
  final initNotifier = ref.read(realtimeInitializationProvider.notifier);
  await initNotifier.initialize();

  ref.onDispose(() async {
    await initNotifier.cleanup();
  });
});

/// Get all subscribed tables
final subscribedTablesProvider = Provider<List<String>>((ref) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  return channelManager.getSubscribedTables();
});

/// Check if a specific table is subscribed
final isTableSubscribedProvider = FamilyProvider<bool, String>((ref, table) {
  final channelManager = ref.watch(realtimeChannelManagerProvider);
  return channelManager.isSubscribed(table);
});
