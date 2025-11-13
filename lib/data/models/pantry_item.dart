import 'package:equatable/equatable.dart';

class PantryItem extends Equatable {
  final String id; // Appwrite document ID
  final String userId; // To link to the user
  final String name;
  final double? quantity;
  final String? unit;
  final double price;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String?
  originalListId; // New field to store the original shopping list ID

  const PantryItem({
    required this.id,
    required this.userId,
    required this.name,
    this.quantity,
    this.unit,
    required this.price,
    required this.purchaseDate,
    this.expiryDate,
    this.originalListId,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    quantity,
    unit,
    price,
    purchaseDate,
    expiryDate,
    originalListId,
  ];

  PantryItem copyWith({
    String? id,
    String? userId,
    String? name,
    double? quantity,
    String? unit,
    double? price,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? originalListId,
  }) {
    return PantryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      originalListId: originalListId ?? this.originalListId,
    );
  }

  // --- Appwrite specific conversion methods ---
  factory PantryItem.fromAppwrite(Map<String, dynamic> json) {
    return PantryItem(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      originalListId: json['originalListId'] as String?,
    );
  }

  Map<String, dynamic> toAppwrite() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'name': name,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
    if (quantity != null) {
      data['quantity'] = quantity;
    }
    if (unit != null) {
      data['unit'] = unit;
    }
    if (expiryDate != null) {
      data['expiryDate'] = expiryDate!.toIso8601String();
    }
    if (originalListId != null) {
      data['originalListId'] = originalListId;
    }
    return data;
  }

  // --- Firebase specific conversion methods (will be unused) ---
  // factory PantryItem.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return PantryItem(
  //     id: doc.id,
  //     userId: data['userId'] as String,
  //     name: data['name'] as String,
  //     quantity: (data['quantity'] as num?)?.toDouble(),
  //     unit: data['unit'] as String?,
  //     purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
  //     expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
  //   );
  // }

  // Map<String, dynamic> toFirestore() {
  //   return {
  //     'userId': userId,
  //     'name': name,
  //     'quantity': quantity,
  //     'unit': unit,
  //     'purchaseDate': Timestamp.fromDate(purchaseDate),
  //     'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
  //   };
  // }
}
