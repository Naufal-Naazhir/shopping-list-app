import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

abstract class AuthRepository extends ChangeNotifier {
  Future<User?> login(String email, String password);
  Future<User?> register(String username, String? email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> initializePremiumAccounts();
  Future<List<User>> getAllUsers(); // New method
  Future<void> deleteUser(String username); // New method
  Future<void> clearAllUsersExceptAdmin(); // New method
  Future<bool> isCurrentUserPremium();
  Future<void> decrementAiUses(User user);
}
