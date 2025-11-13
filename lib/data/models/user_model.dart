import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uid;
  final String username;
  final String? email;
  final bool isPremium;
  final DateTime createdAt;
  final int aiUsesRemaining;
  final List<String> labels;

  const User({
    required this.uid,
    required this.username,
    this.email,
    this.isPremium = false,
    required this.createdAt,
    this.aiUsesRemaining = 5,
    this.labels = const [],
  });

  @override
  List<Object?> get props =>
      [uid, username, email, isPremium, createdAt, aiUsesRemaining, labels];

  User copyWith({
    String? uid,
    String? username,
    String? email,
    bool? isPremium,
    DateTime? createdAt,
    int? aiUsesRemaining,
    List<String>? labels,
  }) {
    return User(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      aiUsesRemaining: aiUsesRemaining ?? this.aiUsesRemaining,
      labels: labels ?? this.labels,
    );
  }

  // --- Appwrite specific conversion methods ---
  factory User.fromAppwrite(Map<String, dynamic> json) {
    final prefs = json['prefs'] as Map<String, dynamic>? ?? {};
    return User(
      uid: json['\$id'] as String, // Correct: Appwrite User ID is '$id'
      username: json['name'] as String, // Correct: Appwrite User name is 'name'
      email: json['email'] as String?,
      isPremium: prefs['isPremium'] as bool? ?? false, // Assumes 'isPremium' is in user prefs
      createdAt: DateTime.parse(
        json['\$createdAt'] as String,
      ),
      aiUsesRemaining: prefs['aiUsesRemaining'] as int? ?? 5, // Assumes 'aiUsesRemaining' is in user prefs
      labels: List<String>.from(json['labels'] ?? []), // Correctly parse labels
    );
  }

  Map<String, dynamic> toAppwrite() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'isPremium': isPremium,
      'aiUsesRemaining': aiUsesRemaining,
      // Appwrite automatically handles $createdAt, $updatedAt, and labels are managed server-side
    };
  }

  // --- Firebase specific conversion methods (will be unused) ---
  factory User.fromFirestore(Map<String, dynamic> json, String uid) {
    return User(
      uid: uid,
      username: json['username'] as String,
      email: json['email'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: (json['createdAt'] as dynamic).toDate(),
      aiUsesRemaining: json['aiUsesRemaining'] as int? ?? 5,
      labels: const [], // Add default value
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'isPremium': isPremium,
      'createdAt': createdAt,
      'aiUsesRemaining': aiUsesRemaining,
    };
  }

  // This is for local model, which is now legacy. (Keep for now, might remove later if not used)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? json['username'], // for backward compatibility
      username: json['username'] as String,
      email: json['email'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      aiUsesRemaining: json['aiUsesRemaining'] as int? ?? 5,
      labels: List<String>.from(json['labels'] ?? []), // Add labels parsing
    );
  }
}
