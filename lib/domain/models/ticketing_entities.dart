class Ticket {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String customerId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.customerId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? customerId,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      customerId: customerId ?? this.customerId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Comment {
  final String id;
  final String ticketId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Comment copyWith({
    String? id,
    String? ticketId,
    String? authorId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Attachment {
  final String id;
  final String ticketId;
  final String? commentId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attachment({
    required this.id,
    required this.ticketId,
    this.commentId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  Attachment copyWith({
    String? id,
    String? ticketId,
    String? commentId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      commentId: commentId ?? this.commentId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
