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
  UserModel? _cachedUser;

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
      // Force refresh user
      _cachedUser = await _fetchUserFromNetwork();
      notifyListeners();
      return _cachedUser;
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

    try {
      // Create user in Appwrite Auth
      final appwriteUser = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: username, // Use name for username in Appwrite Auth
      );

      // CRITICAL FIX: Log the user in immediately after creation
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Create document in our custom users collection
      final newUser = UserModel(
        uid: appwriteUser.$id, // Menggunakan uid
        username: username, // Menggunakan username
        email: email,
        isPremium: false,
        aiUsesRemaining: 5, // Default quota
      );

      await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        documentId: appwriteUser
            .$id, // CRITICAL FIX: Use the Auth User ID as the Document ID
        data: newUser.toJson(),
        permissions: [
          Permission.read(
            Role.user(appwriteUser.$id),
          ), // User can read their own document
          Permission.update(
            Role.user(appwriteUser.$id),
          ), // User can update their own document
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
      _cachedUser = null;
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
    if (_cachedUser != null) return _cachedUser;
    _cachedUser = await _fetchUserFromNetwork();
    return _cachedUser;
  }

  Future<UserModel?> _fetchUserFromNetwork() async {
    try {
      final appwriteAuthUser = await _account.get();
      final userDbDoc = await _getUserDbDoc(appwriteAuthUser.$id);

      // Combine data from Appwrite Auth and our custom DB collection
      final combinedData = appwriteAuthUser.toMap();

      // To match the structure expected by User.fromAppwrite,
      // we inject our custom DB fields into a 'prefs' object.
      if (userDbDoc != null) {
        combinedData['prefs'] = {
          'isPremium':
              userDbDoc.data['isPremium'] ??
              userDbDoc.data['isPremium'] ??
              false,
        };
      } else {
        // If there's no DB doc for some reason, provide default prefs
        combinedData['prefs'] = {'isPremium': false};
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
    if (_cachedUser != null) return true;
    try {
      final user = await getCurrentUser();
      return user != null;
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
    try {
      // Query all documents from the users collection
      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
      );

      // Convert each document to UserModel
      final users = response.documents
          .map((doc) => UserModel.fromJson(doc.data))
          .toList();

      return users;
    } on AppwriteException catch (e) {
      print('Appwrite getAllUsers error: ${e.message}');
      throw Exception(e.message ?? 'Failed to get all users.');
    } catch (e) {
      print('getAllUsers error: $e');
      throw Exception('Failed to get all users.');
    }
  }

  @override
  Future<void> deleteUser(String userUid) async {
    try {
      // 1. Find the user document by uid field
      final userResponse = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        queries: [Query.equal('uid', userUid)],
      );

      if (userResponse.documents.isEmpty) {
        throw Exception('User not found.');
      }

      final userDocId = userResponse.documents.first.$id;

      // 2. Delete all shopping lists belonging to this user
      final listsResponse = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        queries: [Query.equal('userId', userUid)],
      );

      for (final list in listsResponse.documents) {
        // Delete all items in this list
        final itemsResponse = await _databases.listDocuments(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.shoppingItemsCollectionId,
          queries: [Query.equal('listId', list.$id)],
        );

        for (final item in itemsResponse.documents) {
          await _databases.deleteDocument(
            databaseId: AppwriteDB.databaseId,
            collectionId: AppwriteDB.shoppingItemsCollectionId,
            documentId: item.$id,
          );
        }

        // Delete the list itself
        await _databases.deleteDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.shoppingListsCollectionId,
          documentId: list.$id,
        );
      }

      // 3. Delete all pantry items belonging to this user
      final pantryResponse = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.pantryItemsCollectionId,
        queries: [Query.equal('userId', userUid)],
      );

      for (final item in pantryResponse.documents) {
        await _databases.deleteDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.pantryItemsCollectionId,
          documentId: item.$id,
        );
      }

      // 4. Finally, delete the user document
      await _databases.deleteDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        documentId: userDocId,
      );

      print('User $userUid and all their data deleted successfully.');
    } on AppwriteException catch (e) {
      print('Appwrite deleteUser error: ${e.message}');
      throw Exception(e.message ?? 'Failed to delete user.');
    } catch (e) {
      print('deleteUser error: $e');
      throw Exception('Failed to delete user.');
    }
  }

  @override
  Future<void> clearAllUsersExceptAdmin() async {
    try {
      // Get current admin user
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user logged in.');
      }

      // Get all users
      final allUsers = await getAllUsers();

      // Filter out the current admin user
      final usersToDelete = allUsers
          .where((user) => user.uid != currentUser.uid)
          .toList();

      // Delete each non-admin user
      for (final user in usersToDelete) {
        await deleteUser(user.uid);
        print('Deleted user: ${user.username} (${user.uid})');
      }

      print('Cleared ${usersToDelete.length} non-admin users.');
    } on AppwriteException catch (e) {
      print('Appwrite clearAllUsersExceptAdmin error: ${e.message}');
      throw Exception(e.message ?? 'Failed to clear users.');
    } catch (e) {
      print('clearAllUsersExceptAdmin error: $e');
      throw Exception('Failed to clear users.');
    }
  }

  @override
  Future<int> calculateAiQuota(String userId) async {
    try {
      // Count the number of shopping lists the user has
      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        queries: [Query.equal('userId', userId)],
      );

      final listCount = response.documents.length;
      final quota = 5 - listCount;

      // Quota cannot be negative
      return quota < 0 ? 0 : quota;
    } catch (e) {
      print('Error calculating AI quota: $e');
      return 0; // Return 0 on error to be safe
    }
  }

  @override
  Future<bool> isAdmin(String userUid) async {
    try {
      final appwriteAuthUser = await _account
          .get(); // Get current logged in user
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

  @override
  Future<void> refreshUser() async {
    try {
      _cachedUser = null; // Clear cache
      _cachedUser = await _fetchUserFromNetwork(); // Force fresh fetch
      notifyListeners(); // Notify all listeners
      print(
        'User refreshed successfully. isPremium: ${_cachedUser?.isPremium}',
      );
    } catch (e) {
      print('Error refreshing user: $e');
      rethrow;
    }
  }
}
