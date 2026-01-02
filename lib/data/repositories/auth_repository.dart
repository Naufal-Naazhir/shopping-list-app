import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

abstract class AuthRepository extends ChangeNotifier {
  Client get client; // Add this getter
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String username, String? email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> initializePremiumAccounts();
  Future<List<UserModel>> getAllUsers(); // New method
  Future<void> deleteUser(String userUid); // New method
  Future<void> clearAllUsersExceptAdmin(); // New method
  Future<bool> isCurrentUserPremium();
  Future<int> calculateAiQuota(
    String userId,
  ); // NEW: Calculate quota dynamically
  Future<bool> isAdmin(String userUid); // Tambahkan ini
  Future<void> refreshUser();
}
