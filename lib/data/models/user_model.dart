class UserModel {
  final String uid;
  final String username;
  final String email;
  final bool isPremium;
  final int aiUsesRemaining;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.isPremium = false,
    this.aiUsesRemaining = 5,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // This factory now needs to be robust. It might get data from Appwrite Auth
    // which has 'name' but our DB has 'username'. We prioritize DB fields.
    // It also handles the 'prefs' object from the old implementation.
    return UserModel(
      uid: json['uid'] ?? json['\$id'] ?? '',
      username: json['username'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      isPremium: json['isPremium'] ?? json['prefs']?['isPremium'] ?? false,
      aiUsesRemaining: json['aiUsesRemaining'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'isPremium': isPremium,
      'aiUsesRemaining': aiUsesRemaining,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    bool? isPremium,
    int? aiUsesRemaining,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      aiUsesRemaining: aiUsesRemaining ?? this.aiUsesRemaining,
    );
  }
}
