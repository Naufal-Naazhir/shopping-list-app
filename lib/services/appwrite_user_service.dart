import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/appwrite_db.dart'; // Ubah ini
import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:get_it/get_it.dart';

class AppwriteUserService {
  final Databases _databases;
  final Logger _logger;

  AppwriteUserService()
      : _databases = Databases(GetIt.I<Client>()),
        _logger = Logger();

  // Method to get the current user's premium status
  Future<UserModel?> getUserModel(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.usersCollectionId,
        queries: [
          Query.equal('uid', userId), // Cari dokumen dimana field 'uid' sama dengan userId
        ],
      );

      if (response.documents.isEmpty) {
        _logger.w('AppwriteUserService: User document with uid $userId not found.');
        return null;
      }
      
      return UserModel.fromJson(response.documents.first.data);
    } on AppwriteException catch (e) {
      _logger.e('AppwriteUserService: Error getting user document: ${e.message}', error: e);
      return null;
    } catch (e) {
      _logger.e('AppwriteUserService: Unexpected error getting user document: $e', error: e);
      return null;
    }
  }

  // Method to check if user is premium
  Future<bool> isUserPremium(String userId) async {
    final userModel = await getUserModel(userId);
    return userModel?.isPremium ?? false;
  }
}
