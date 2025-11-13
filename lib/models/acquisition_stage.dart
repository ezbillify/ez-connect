class AcquisitionStage {
  final String id;
  final String name;
  final int order;
  final DateTime createdAt;

  const AcquisitionStage({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  factory AcquisitionStage.fromJson(Map<String, dynamic> json) {
    return AcquisitionStage(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<AcquisitionStage> get defaultStages => [
    AcquisitionStage(
      id: 'lead',
      name: 'Lead',
      order: 1,
      createdAt: DateTime.now(),
    ),
    AcquisitionStage(
      id: 'qualified',
      name: 'Qualified',
      order: 2,
      createdAt: DateTime.now(),
    ),
    AcquisitionStage(
      id: 'proposal',
      name: 'Proposal',
      order: 3,
      createdAt: DateTime.now(),
    ),
    AcquisitionStage(
      id: 'negotiation',
      name: 'Negotiation',
      order: 4,
      createdAt: DateTime.now(),
    ),
    AcquisitionStage(
      id: 'closed_won',
      name: 'Closed Won',
      order: 5,
      createdAt: DateTime.now(),
    ),
    AcquisitionStage(
      id: 'closed_lost',
      name: 'Closed Lost',
      order: 6,
      createdAt: DateTime.now(),
    ),
  ];
}
