import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/models/pantry_item.dart'; // New import

abstract class ShoppingListRepository {
  Future<void> init(); // Method to initialize the repository
  Stream<List<ShoppingList>> getShoppingLists(); // Returns a stream of lists
  Future<ShoppingList?> getShoppingListById(String id);
  Future<ShoppingList> addList(ShoppingList list);
  Future<void> updateList(ShoppingList list);
  Future<void> deleteList(String id);
  Future<void> deleteListAndMoveItemsToPantry(String listId);

  // Item related methods
  Future<void> addItemToList(String listId, ShoppingItem item);
  Future<void> updateItemInList(String listId, ShoppingItem item);
  Future<void> deleteItemFromList(String listId, String itemId);
  Future<void> toggleItemCompletion(
    String listId,
    String itemId,
    bool isCompleted,
  );
  Future<void> moveItemToPantry(
    String listId,
    ShoppingItem item, {
    DateTime? expiryDate,
  });
  Future<String?> returnPantryItemToList(
    PantryItem item,
  ); // New method signature
  Future<List<ShoppingItem>> getShoppingItems(String listId);
}
