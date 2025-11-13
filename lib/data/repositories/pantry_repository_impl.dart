import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/appwrite_db.dart';
import 'package:belanja_praktis/data/models/pantry_item.dart';
import 'package:belanja_praktis/data/repositories/pantry_repository.dart';

class PantryRepositoryImpl implements PantryRepository {
  final Databases _databases;
  final Realtime _realtime; // Use Realtime service
  final Account _account;

  PantryRepositoryImpl(this._databases, this._realtime, this._account);

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
  Stream<List<PantryItem>> getPantryItems() {
    late StreamController<List<PantryItem>> controller;
    RealtimeSubscription? realtimeSubscription;

    Future<void> fetchAndPushItems() async {
      try {
        final userId = await _getCurrentUserId();
        final response = await _databases.listDocuments(
          databaseId: AppwriteDB.databaseId,
          collectionId: AppwriteDB.pantryItemsCollectionId,
          queries: [
            Query.equal('userId', userId),
            Query.orderDesc('purchaseDate'),
          ],
        );

        // Safer parsing logic
        final items = <PantryItem>[];
        for (final doc in response.documents) {
          try {
            items.add(PantryItem.fromAppwrite(doc.data));
          } catch (e) {
            print('Failed to parse pantry item ${doc.$id}: $e');
          }
        }
        if (!controller.isClosed) {
          controller.add(items);
        }
      } catch (e) {
        print('Error fetching pantry items: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<List<PantryItem>>.broadcast(
      onListen: () {
        // Fetch initial data when the first listener subscribes
        fetchAndPushItems();

        // Set up the realtime subscription
        realtimeSubscription = _realtime.subscribe([
          'databases.${AppwriteDB.databaseId}.collections.${AppwriteDB.pantryItemsCollectionId}.documents',
        ]);

        // On a realtime event, re-fetch all data
        realtimeSubscription!.stream.listen((_) {
          fetchAndPushItems();
        });
      },
      onCancel: () {
        // Close the realtime subscription when there are no more listeners
        realtimeSubscription?.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> addPantryItem(PantryItem item) async {
    try {
      final userId = await _getCurrentUserId();
      await _databases.createDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.pantryItemsCollectionId,
        documentId: ID.unique(),
        data: item.copyWith(userId: userId).toAppwrite(),
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } on AppwriteException catch (e) {
      print('Error adding pantry item: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> updatePantryItem(PantryItem item) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.pantryItemsCollectionId,
        documentId: item.id,
        data: item.toAppwrite(),
      );
    } on AppwriteException catch (e) {
      print('Error updating pantry item: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> deletePantryItem(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteDB.databaseId,
        collectionId: AppwriteDB.pantryItemsCollectionId,
        documentId: id,
      );
    } on AppwriteException catch (e) {
      print('Error deleting pantry item: ${e.message}');
      rethrow;
    }
  }
}
