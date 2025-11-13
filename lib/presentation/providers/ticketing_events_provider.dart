import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/domain/models/realtime_event.dart';
import 'package:app/domain/models/ticketing_entities.dart';
import 'package:app/presentation/providers/realtime_provider.dart';

/// Ticket events stream
final ticketEventsProvider = StreamProvider<RealtimeEvent<Ticket>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final ticketingRepo = ref.watch(ticketingRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Ticket>>();

  dispatcher.on<Ticket>('tickets', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await ticketingRepo.subscribeToTickets();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('tickets');
  });

  yield* controller.stream;
});

/// Comment events stream
final commentEventsProvider = StreamProvider<RealtimeEvent<Comment>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final ticketingRepo = ref.watch(ticketingRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Comment>>();

  dispatcher.on<Comment>('comments', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await ticketingRepo.subscribeToComments();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('comments');
  });

  yield* controller.stream;
});

/// Attachment events stream
final attachmentEventsProvider = StreamProvider<RealtimeEvent<Attachment>>((ref) async* {
  final dispatcher = ref.watch(realtimeEventDispatcherProvider);
  final ticketingRepo = ref.watch(ticketingRealtimeRepositoryProvider);

  final controller = StreamController<RealtimeEvent<Attachment>>();

  dispatcher.on<Attachment>('attachments', (event) {
    if (!controller.isClosed) {
      controller.add(event);
    }
  });

  await ticketingRepo.subscribeToAttachments();

  ref.onDispose(() async {
    await controller.close();
    dispatcher.clearChannel('attachments');
  });

  yield* controller.stream;
});
