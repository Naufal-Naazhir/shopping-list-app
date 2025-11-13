import 'package:belanja_praktis/data/models/pantry_item.dart';

abstract class PantryRepository {
  Stream<List<PantryItem>> getPantryItems();
  Future<void> addPantryItem(PantryItem item);
  Future<void> updatePantryItem(PantryItem item);
  Future<void> deletePantryItem(String id);
}
