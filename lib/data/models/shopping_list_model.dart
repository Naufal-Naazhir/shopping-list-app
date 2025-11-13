import 'package:equatable/equatable.dart';

class ShoppingItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final bool isBought;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.isBought = false,
  });

  @override
  List<Object> get props => [id, name, quantity, price, isBought];

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    bool? isBought,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isBought: isBought ?? this.isBought,
    );
  }

  // --- Appwrite specific conversion methods ---
  factory ShoppingItem.fromAppwrite(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['\$id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      isBought: json['isBought'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toAppwrite() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'isBought': isBought,
      // 'listId': listId, // This will be added by the repository
    };
  }

  // --- Firebase specific conversion methods (will be unused) ---
  // factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return ShoppingItem(
  //     id: doc.id,
  //     name: data['name'] as String,
  //     quantity: data['quantity'] as int,
  //     price: (data['price'] as num).toDouble(),
  //     isBought: data['isBought'] as bool? ?? false,
  //   );
  // }

  // Map<String, dynamic> toFirestore() {
  //   return {
  //     'name': name,
  //     'quantity': quantity,
  //     'price': price,
  //     'isBought': isBought,
  //   };
  // }
}

class ShoppingList extends Equatable {
  final String id;
  final String userId;
  final String name;
  final List<ShoppingItem>
  items; // This will not be stored directly in the document
  final DateTime createdAt;
  final DateTime? lastUpdated; // New field to trigger updates

  const ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    this.items = const [],
    required this.createdAt,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [id, userId, name, items, createdAt, lastUpdated];

  ShoppingList copyWith({
    String? id,
    String? userId,
    String? name,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // --- Appwrite specific conversion methods ---
  factory ShoppingList.fromAppwrite(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['\$createdAt'] as String),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      items: const [], // Items are in a separate collection
    );
  }

  Map<String, dynamic> toAppwrite() {
    return {
      'userId': userId,
      'name': name,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  // --- Firebase specific conversion methods (will be unused) ---
  // factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return ShoppingList(
  //     id: doc.id,
  //     userId: data['userId'] as String,
  //     name: data['name'] as String,
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     // items are loaded from a sub-collection, so default to empty here
  //     items: const [],
  //   );
  // }

  // Map<String, dynamic> toFirestore() {
  //   return {
  //     'userId': userId,
  //     'name': name,
  //     'createdAt': Timestamp.fromDate(createdAt),
  //   };
  // }
}
