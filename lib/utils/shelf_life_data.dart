// lib/utils/shelf_life_data.dart

// Hardcoded shelf life data in days for common items.
// Keys are lowercase item names.
// Values are suggested shelf life in days when stored appropriately (e.g., refrigerated for dairy).
const Map<String, int> shelfLifeData = {
  'susu': 7, // Milk, refrigerated
  'roti': 5, // Bread, room temperature
  'telur': 21, // Eggs, refrigerated
  'daging ayam': 2, // Chicken meat, refrigerated
  'daging sapi': 3, // Beef, refrigerated
  'ikan': 1, // Fish, refrigerated
  'sayuran hijau': 5, // Leafy greens, refrigerated
  'buah-buahan': 7, // General fruits, refrigerated
  'yogurt': 14, // Yogurt, refrigerated
  'keju': 28, // Cheese, refrigerated
  'mentega': 30, // Butter, refrigerated
  'nasi': 4, // Cooked rice, refrigerated
  'pasta': 5, // Cooked pasta, refrigerated
  'sosis': 7, // Sausages, refrigerated
  'ham': 7, // Ham, refrigerated
  'jus': 7, // Juice, refrigerated after opening
  'selai': 30, // Jam, refrigerated after opening
  'kecap': 365, // Soy sauce, room temperature/refrigerated
  'saus tomat': 30, // Ketchup, refrigerated after opening
  'mayones': 30, // Mayonnaise, refrigerated after opening
};

// Function to get suggested shelf life in days
int getSuggestedShelfLifeDays(String itemName) {
  // Normalize item name to lowercase for lookup
  final normalizedName = itemName.toLowerCase();

  // Check for exact match
  if (shelfLifeData.containsKey(normalizedName)) {
    return shelfLifeData[normalizedName]!;
  }

  // Check for partial matches (e.g., "susu segar" should match "susu")
  for (final key in shelfLifeData.keys) {
    if (normalizedName.contains(key)) {
      return shelfLifeData[key]!;
    }
  }

  // Default shelf life if no match is found
  return 7; // Default to 7 days if no specific data is available
}
