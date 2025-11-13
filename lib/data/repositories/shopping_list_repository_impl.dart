import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';

import 'package:belanja_praktis/data/models/pantry_item.dart';
import 'package:belanja_praktis/data/repositories/pantry_repository.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final Databases _databases;
  final Realtime _realtime; // Use Realtime service
  final Account _account;
  final PantryRepository _pantryRepository;

  ShoppingListRepositoryImpl(
    this._databases,
    this._realtime,
    this._account,
    this._pantryRepository,
  );

  // Helper to get current user ID asynchronously
  Future<String> _getCurrentUserId() async {
    try {
      final user = await _account.get();
      return user.$id;
    } catch (e) {
      throw Exception('User not logged in');
    }
  }

  @override
  Stream<List<ShoppingList>> getShoppingLists() {
    final controller = StreamController<List<ShoppingList>>();

    Future<void> fetchAndPushLists() async {
      try {
        final userId = await _getCurrentUserId();
        final response = await _databases.listDocuments(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.shoppingListsCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.orderDesc('\$createdAt'),
          ],
        );
        controller.add(
          response.documents
              .map((doc) => ShoppingList.fromAppwrite(doc.data))
              .toList(),
        );
      } catch (e) {
        print('Error fetching shopping lists: $e');
        controller.addError(e);
      }
    }

    // Initial fetch
    fetchAndPushLists();

    // Subscribe to real-time updates
    final subscription = _realtime.subscribe([
      'databases.${AppwriteDB.databaseId}.collections.${AppwriteDB.shoppingListsCollectionId}.documents',
    ]);

    final streamSubscription = subscription.stream.listen((response) async {
      try {
        final userId = await _getCurrentUserId();
        final eventUserId = response.payload['userId'];
        if (eventUserId == userId) {
          // Re-fetch all lists to ensure consistency
          fetchAndPushLists();
        }
      } catch (e) {
        // Ignore errors if user is logged out during a real-time event
      }
    });

    // Close the subscription when the stream is cancelled
    controller.onCancel = () {
      streamSubscription.cancel();
    };

    return controller.stream;
  }

  @override
  Future<ShoppingList?> getShoppingListById(String id) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        documentId: id,
      );
      return ShoppingList.fromAppwrite(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null; // Document not found
      print('Error getting shopping list by ID: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<ShoppingList> addList(ShoppingList list) async {
    try {
      final userId = await _getCurrentUserId();
      final document = await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        documentId: ID.unique(),
        data: list.copyWith(userId: userId).toAppwrite(),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
      return ShoppingList.fromAppwrite(document.data);
    } on AppwriteException catch (e) {
      print('Error adding shopping list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        documentId: list.id,
        data: list.toAppwrite(),
      );
    } on AppwriteException catch (e) {
      print('Error updating shopping list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    try {
      // Delete all items associated with this list first
      final itemsResponse = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        queries: [Query.equal('listId', id)],
      );
      for (var doc in itemsResponse.documents) {
        await _databases.deleteDocument(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.shoppingItemsCollectionId,
          documentId: doc.$id,
        );
      }

      // Then delete the list itself
      await _databases.deleteDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        documentId: id,
      );
    } on AppwriteException catch (e) {
      print('Error deleting shopping list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<List<ShoppingItem>> getShoppingItems(String listId) async {
    try {
      // Security check: Ensure the list belongs to the current user
      final list = await getShoppingListById(listId);
      final userId = await _getCurrentUserId();
      if (list == null || list.userId != userId) {
        // If list doesn't exist or doesn't belong to the user, return empty list
        // or throw an exception, depending on desired behavior.
        // Returning empty is safer to not reveal existence of a list.
        return [];
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        queries: [
          Query.equal('listId', listId),
          Query.orderAsc('\$createdAt'), // Order items by creation time
        ],
      );
      return response.documents
          .map((doc) => ShoppingItem.fromAppwrite(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      print('Error getting shopping items: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    try {
      final userId = await _getCurrentUserId();
      await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        documentId: ID.unique(),
        data: item.toAppwrite()..['listId'] = listId, // Add listId to item data
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (e) {
      print('Error adding item to list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> updateItemInList(String listId, ShoppingItem item) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        documentId: item.id,
        data: item.toAppwrite()
          ..['listId'] = listId, // Ensure listId is present
      );
    } on AppwriteException catch (e) {
      print('Error updating item in list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> deleteItemFromList(String listId, String itemId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        documentId: itemId,
      );
    } on AppwriteException catch (e) {
      print('Error deleting item from list: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> toggleItemCompletion(
    String listId,
    String itemId,
    bool isCompleted,
  ) async {
    try {
      // 1. Update the item itself
      await _databases.updateDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingItemsCollectionId,
        documentId: itemId,
        data: {'isBought': isCompleted},
      );

      // 2. Update the parent list's lastUpdated field to trigger realtime updates
      await _databases.updateDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.shoppingListsCollectionId,
        documentId: listId,
        data: {'lastUpdated': DateTime.now().toIso8601String()},
      );
    } on AppwriteException catch (e) {
      print('Error toggling item completion: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> init() async {
    // No-op, as Appwrite client is initialized via GetIt
  }

  @override
  Future<void> moveItemToPantry(
    String listId,
    ShoppingItem item, {
    DateTime? expiryDate,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final pantryItem = PantryItem(
        id: '', // Will be generated by the database
        userId: userId,
        name: item.name,
        quantity: item.quantity.toDouble(),
        price: item.price,
        purchaseDate: DateTime.now(),
        expiryDate: expiryDate,
        originalListId: listId, // Save the original list ID
      );

      // Add the new item to the pantry
      await _pantryRepository.addPantryItem(pantryItem);

      // Delete the old item from the shopping list
      await deleteItemFromList(listId, item.id);
    } on AppwriteException catch (e) {
      print('Error moving item to pantry: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> deleteListAndMoveItemsToPantry(String listId) async {
    try {
      // Get all items from the list before deleting it
      final items = await getShoppingItems(listId);

      // Filter for items that were actually bought
      final boughtItems = items.where((item) => item.isBought);

      // Add each bought item to the pantry
      for (final item in boughtItems) {
        final userId = await _getCurrentUserId();
        final pantryItem = PantryItem(
          id: '', // Will be generated by the database
          userId: userId,
          name: item.name,
          quantity: item.quantity.toDouble(),
          price: item.price,
          purchaseDate: DateTime.now(),
          originalListId: listId, // FIX: Save the original list ID
        );
        await _pantryRepository.addPantryItem(pantryItem);
      }

      // Finally, delete the list (which also deletes its items)
      await deleteList(listId);
    } on AppwriteException catch (e) {
      print('Error in deleteListAndMoveItemsToPantry: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<String?> returnPantryItemToList(PantryItem item) async {
    if (item.originalListId == null) {
      return 'Cannot return item to list: originalListId is null.';
    }
    try {
      // Check if the original list still exists
      final originalList = await getShoppingListById(item.originalListId!);
      if (originalList == null) {
        return 'Original shopping list no longer exists.';
      }

      // 1. Create a ShoppingItem from the PantryItem
      final shoppingItem = ShoppingItem(
        id: '', // Will be generated by the database
        name: item.name,
        quantity:
            item.quantity?.toInt() ?? 1, // Convert double to int, default to 1
        price: item.price, // Restore the price from the pantry item
        isBought:
            false, // It's being returned to a shopping list, so it's not bought yet
      );

      // 2. Add it back to the original shopping list
      await addItemToList(item.originalListId!, shoppingItem);

      // 3. Delete the item from the pantry
      await _pantryRepository.deletePantryItem(item.id);
      return null; // Success
    } on AppwriteException catch (e) {
      print('Error returning pantry item to list: ${e.message}');
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return e.toString();
    }
  }
}
