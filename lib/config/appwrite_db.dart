import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteDB {
  static final String databaseId = dotenv.env['APPWRITE_DATABASE_ID'] ?? 'YOUR_DEFAULT_DATABASE_ID';
  static const String usersCollectionId = 'users';
  static const String shoppingListsCollectionId = 'shopping_lists';
  static const String shoppingItemsCollectionId = 'shopping_items';
  static const String pantryItemsCollectionId = 'pantry_items';
}
