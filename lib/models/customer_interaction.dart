enum InteractionChannel {
  phone,
  email,
  meeting,
  chat,
  other;

  String get displayName => switch (this) {
    phone => 'Phone',
    email => 'Email',
    meeting => 'Meeting',
    chat => 'Chat',
    other => 'Other',
  };
}

class CustomerInteraction {
  final String id;
  final String customerId;
  final String type;
  final InteractionChannel channel;
  final String note;
  final DateTime? followUpDate;
  final DateTime createdAt;

  const CustomerInteraction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.channel,
    required this.note,
    this.followUpDate,
    required this.createdAt,
  });

  factory CustomerInteraction.fromJson(Map<String, dynamic> json) {
    return CustomerInteraction(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      type: json['type'] as String,
      channel: InteractionChannel.values.firstWhere(
        (e) => e.name == json['channel'],
        orElse: () => InteractionChannel.other,
      ),
      note: json['note'] as String,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'type': type,
      'channel': channel.name,
      'note': note,
      'follow_up_date': followUpDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  CustomerInteraction copyWith({
    String? id,
    String? customerId,
    String? type,
    InteractionChannel? channel,
    String? note,
    DateTime? followUpDate,
    DateTime? createdAt,
  }) {
    return CustomerInteraction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      note: note ?? this.note,
      followUpDate: followUpDate ?? this.followUpDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
