class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? productId;
  final String status;
  final String? acquisitionSource;
  final String? owner;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.productId,
    required this.status,
    this.acquisitionSource,
    this.owner,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      productId: json['product_id'] as String?,
      status: json['status'] as String? ?? 'lead',
      acquisitionSource: json['acquisition_source'] as String?,
      owner: json['owner'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'product_id': productId,
      'status': status,
      'acquisition_source': acquisitionSource,
      'owner': owner,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? productId,
    String? status,
    String? acquisitionSource,
    String? owner,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      acquisitionSource: acquisitionSource ?? this.acquisitionSource,
      owner: owner ?? this.owner,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
