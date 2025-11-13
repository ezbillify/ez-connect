class Product {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Acquisition {
  final String id;
  final String customerId;
  final String productId;
  final int quantity;
  final double totalAmount;
  final DateTime acquiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Acquisition({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.quantity,
    required this.totalAmount,
    required this.acquiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Acquisition copyWith({
    String? id,
    String? customerId,
    String? productId,
    int? quantity,
    double? totalAmount,
    DateTime? acquiredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Acquisition(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Interaction {
  final String id;
  final String customerId;
  final String type;
  final String? notes;
  final DateTime interactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interaction({
    required this.id,
    required this.customerId,
    required this.type,
    this.notes,
    required this.interactionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Interaction copyWith({
    String? id,
    String? customerId,
    String? type,
    String? notes,
    DateTime? interactionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      interactionAt: interactionAt ?? this.interactionAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
