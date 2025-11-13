import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/domain/models/crm_entities.dart';
import 'package:app/domain/models/realtime_event.dart';
import 'package:app/presentation/providers/realtime_provider.dart';

/// Product events stream
final productEventsProvider = StreamProvider<RealtimeEvent<Product>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final crmRepo = ref.watch(crmRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Product>>();

  dispatcher.on<Product>('products', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await crmRepo.subscribeToProducts();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('products');
  });

  yield* controller.stream;
});

/// Customer events stream
final customerEventsProvider = StreamProvider<RealtimeEvent<Customer>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final crmRepo = ref.watch(crmRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Customer>>();

  dispatcher.on<Customer>('customers', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await crmRepo.subscribeToCustomers();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('customers');
  });

  yield* controller.stream;
});

/// Acquisition events stream
final acquisitionEventsProvider = StreamProvider<RealtimeEvent<Acquisition>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final crmRepo = ref.watch(crmRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Acquisition>>();

  dispatcher.on<Acquisition>('acquisitions', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await crmRepo.subscribeToAcquisitions();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('acquisitions');
  });

  yield* controller.stream;
});

/// Interaction events stream
final interactionEventsProvider = StreamProvider<RealtimeEvent<Interaction>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final crmRepo = ref.watch(crmRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Interaction>>();

  dispatcher.on<Interaction>('interactions', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await crmRepo.subscribeToInteractions();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('interactions');
  });

  yield* controller.stream;
});
