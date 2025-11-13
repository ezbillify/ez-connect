import 'package:app/data/services/realtime_channel_manager.dart';
import 'package:app/data/services/realtime_event_dispatcher.dart';
import 'package:app/domain/models/realtime_event.dart';
import 'package:app/domain/models/ticketing_entities.dart';

class TicketingRealtimeRepository {
  final RealtimeChannelManager channelManager;
  final RealtimeEventDispatcher eventDispatcher;

  TicketingRealtimeRepository({
    required this.channelManager,
    required this.eventDispatcher,
  });

  Future<void> subscribeToTickets() async {
    await channelManager.subscribe(
      table: 'tickets',
      onEvent: (data) => _handleTicketEvent(data),
    );
  }

  Future<void> subscribeToComments() async {
    await channelManager.subscribe(
      table: 'comments',
      onEvent: (data) => _handleCommentEvent(data),
    );
  }

  Future<void> subscribeToAttachments() async {
    await channelManager.subscribe(
      table: 'attachments',
      onEvent: (data) => _handleAttachmentEvent(data),
    );
  }

  void _handleTicketEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'tickets',
    );

    try {
      final ticket = _mapToTicket(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Ticket>(
        type: event.type,
        data: ticket,
        table: 'tickets',
      ));
    } catch (e) {
      print('Error handling ticket event: $e');
    }
  }

  void _handleCommentEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'comments',
    );

    try {
      final comment = _mapToComment(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Comment>(
        type: event.type,
        data: comment,
        table: 'comments',
      ));
    } catch (e) {
      print('Error handling comment event: $e');
    }
  }

  void _handleAttachmentEvent(Map<String, dynamic> data) {
    final event = RealtimeEventDispatcher.parseEvent(
      rawData: data,
      table: 'attachments',
    );

    try {
      final attachment = _mapToAttachment(data['new'] ?? data['old'] ?? {});
      eventDispatcher.emit(RealtimeEvent<Attachment>(
        type: event.type,
        data: attachment,
        table: 'attachments',
      ));
    } catch (e) {
      print('Error handling attachment event: $e');
    }
  }

  Ticket _mapToTicket(Map<String, dynamic> data) {
    return Ticket(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      status: data['status'] as String? ?? 'open',
      priority: data['priority'] as String? ?? 'medium',
      customerId: data['customer_id'] as String? ?? '',
      assignedTo: data['assigned_to'] as String?,
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  Comment _mapToComment(Map<String, dynamic> data) {
    return Comment(
      id: data['id'] as String? ?? '',
      ticketId: data['ticket_id'] as String? ?? '',
      authorId: data['author_id'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
    );
  }

  Attachment _mapToAttachment(Map<String, dynamic> data) {
    return Attachment(
      id: data['id'] as String? ?? '',
      ticketId: data['ticket_id'] as String? ?? '',
      commentId: data['comment_id'] as String?,
      fileName: data['file_name'] as String? ?? '',
      fileUrl: data['file_url'] as String? ?? '',
      fileType: data['file_type'] as String? ?? '',
      fileSize: data['file_size'] as int? ?? 0,
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
    await channelManager.unsubscribe(table: 'tickets');
    await channelManager.unsubscribe(table: 'comments');
    await channelManager.unsubscribe(table: 'attachments');
  }
}
