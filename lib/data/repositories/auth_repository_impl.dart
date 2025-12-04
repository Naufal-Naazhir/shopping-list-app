import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl extends ChangeNotifier implements AuthRepository {
  final Client _client; // Store the client
  final Account _account;
  final Databases _databases;

  AuthRepositoryImpl(this._client, this._account, this._databases);

  @override
  Client get client => _client; // Implement the getter

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      notifyListeners();
      // After successful login, get the combined user details.
      return await getCurrentUser();
    } on AppwriteException catch (e) {
      print('Appwrite login error: ${e.message}');
      throw Exception(e.message ?? 'Login failed.');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed.');
    }
  }

  @override
  Future<UserModel?> register(
    String username,
    String? email,
    String password,
  ) async {
    if (email == null || email.isEmpty) {
      throw Exception('Email is required for registration.');
    }

    // Check if username is unique in our custom users collection
    /* This check is commented out because it requires read access for unauthenticated
     * users, which is a security risk. User uniqueness will be enforced by email.
    try {
      final usernameQuery = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        queries: [Query.equal('username', username)],
      );
      if (usernameQuery.documents.isNotEmpty) {
        throw Exception('Username is already taken.');
      }
    } catch (e) {
      print('Error checking username uniqueness: $e');
      throw Exception('Failed to check username uniqueness.');
    }
    */

    try {
      // Create user in Appwrite Auth
      final appwriteUser = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: username, // Use name for username in Appwrite Auth
      );

      // CRITICAL FIX: Log the user in immediately after creation
      await _account.createEmailPasswordSession(email: email, password: password);

      // Create document in our custom users collection
      final newUser = UserModel(
        uid: appwriteUser.$id, // Menggunakan uid
        username: username,    // Menggunakan username
        email: email,
        isPremium: false,
        aiUsesRemaining: 5,
      );

      await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        documentId: appwriteUser.$id, // CRITICAL FIX: Use the Auth User ID as the Document ID
        data: newUser.toJson(),
        permissions: [
          Permission.read(Role.user(appwriteUser.$id)), // User can read their own document
          Permission.update(Role.user(appwriteUser.$id)), // User can update their own document
        ],
      );

      // Log the user out immediately after registration to force them to the login screen
      await logout();

      return newUser;
    } on AppwriteException catch (e) {
      print('Appwrite registration error: ${e.message}');
      throw Exception(e.message ?? 'Registration failed.');
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      notifyListeners();
    } on AppwriteException catch (e) {
      print('Appwrite logout error: ${e.message}');
      throw Exception(e.message ?? 'Logout failed.');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed.');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final appwriteAuthUser = await _account.get();
      final userDbDoc = await _getUserDbDoc(appwriteAuthUser.$id);

      // Combine data from Appwrite Auth and our custom DB collection
      final combinedData = appwriteAuthUser.toMap();

      // To match the structure expected by User.fromAppwrite,
      // we inject our custom DB fields into a 'prefs' object.
      if (userDbDoc != null) {
        combinedData['prefs'] = {
          'isPremium': userDbDoc.data['isPremium'] ?? false,
          'aiUsesRemaining': userDbDoc.data['aiUsesRemaining'] ?? 5,
        };
      } else {
        // If there's no DB doc for some reason, provide default prefs
        combinedData['prefs'] = {
          'isPremium': false,
          'aiUsesRemaining': 5,
        };
      }

      return UserModel.fromJson(combinedData);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // User not logged in
        return null;
      }
      print('Appwrite getCurrentUser error: ${e.message}');
      return null;
    } catch (e) {
      print('getCurrentUser error: $e');
      return null;
    }
  }

  Future<models.Document?> _getUserDbDoc(String uid) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        queries: [
          Query.equal('uid', uid), // Query by the 'uid' field
        ],
      );

      return response.documents.isNotEmpty ? response.documents.first : null;
    } catch (e) {
      print('Error fetching user DB doc: $e');
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // User not logged in
        return false;
      }
      print('Appwrite isLoggedIn error: ${e.message}');
      return false; // Assume not logged in on other errors for simplicity
    } catch (e) {
      print('isLoggedIn error: $e');
      return false;
    }
  }

  @override
  Future<bool> isCurrentUserPremium() async {
    final user = await getCurrentUser();
    return user?.isPremium ?? false;
  }

  @override
  Future<void> initializePremiumAccounts() async {
    // This method was a no-op in the Firebase version, keeping it as such.
    return;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    throw UnimplementedError(
      'This function requires admin privileges and is not implemented in the client.',
    );
  }

  @override
  Future<void> deleteUser(String userUid) async {
    throw UnimplementedError(
      'This function requires admin privileges and is not implemented in the client.',
    );
  }

  @override
  Future<void> clearAllUsersExceptAdmin() async {
    throw UnimplementedError(
      'This function requires admin privileges and is not implemented in the client.',
    );
  }

  @override
  Future<void> decrementAiUses(UserModel user) async {
    // As per user's request, AI usage is no longer limited for any user.
    // The decrement operation is now a no-op.
    return;
  }

  @override
  Future<bool> isAdmin(String userUid) async {
    try {
      final appwriteAuthUser = await _account.get(); // Get current logged in user
      return appwriteAuthUser.labels.contains('admin');
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // Not logged in or session expired
        return false;
      }
      print('Appwrite isAdmin error: ${e.message}');
      return false;
    } catch (e) {
      print('isAdmin error: $e');
      return false;
    }
  }
}
