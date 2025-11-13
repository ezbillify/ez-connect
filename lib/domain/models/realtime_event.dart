enum RealtimeEventType {
  insert,
  update,
  delete,
}

class RealtimeEvent<T> {
  final RealtimeEventType type;
  final T data;
  final String table;

  RealtimeEvent({
    required this.type,
    required this.data,
    required this.table,
  });
}
