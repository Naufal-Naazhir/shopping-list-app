import 'package:intl/intl.dart';

class PriceUtils {
  static final Map<String, int> _priceDatabase = {
    'beras 5kg': 65000,
    'beras': 13000,
    'minyak goreng 2l': 32000,
    'minyak goreng': 16000,
    'minyak': 16000,
    'gula pasir 1kg': 15000,
    'gula pasir': 15000,
    'gula': 15000,
    'telur 1kg': 28000,
    'telur': 28000,
    'susu uht': 12000,
    'susu': 12000,
    'roti tawar': 14000,
    'roti': 10000,
    'sabun mandi': 8000,
    'sabun': 5000,
    'deterjen': 18000,
    'shampo': 15000,
    'pasta gigi': 12000,
    'tisu': 8000,
    'sayur bayam': 5000,
    'bayam': 5000,
    'wortel': 8000,
    'kentang': 12000,
    'bawang merah': 35000,
    'bawang putih': 40000,
    'cabai': 25000,
    'cabe': 25000,
    'tomat': 10000,
    'daging ayam': 35000,
    'ayam': 35000,
    'ikan': 40000,
    'ikan segar': 45000,
    'tempe': 8000,
    'tahu': 6000,
    'sayur kangkung': 4000,
    'kangkung': 4000,
    'cabai rawit': 30000,
    'jahe': 15000,
    'kunyit': 12000,
    'lengkuas': 10000,
    'daun salam': 5000,
    'serai': 3000,
    'selai': 18000,
    'mentega': 22000,
    'sereal': 35000,
    'keju': 45000,
    'yogurt': 15000,
    'oatmeal': 28000,
    'madu': 40000,
    'nasi': 5000,
    'sambal': 8000,
    'lauk pauk': 20000,
    'lauk': 20000,
    'sop': 15000,
    'sup': 15000,
    'kerupuk': 5000,
    'sayur': 8000,
    'buah': 15000,
    'salad': 20000,
    'protein': 35000,
    'karbohidrat': 10000,
    'minuman': 8000,
    'dessert': 25000,
    'keripik': 10000,
    'coklat': 15000,
    'biskuit': 12000,
    'permen': 5000,
    'kacang': 15000,
    'wafer': 8000,
    'cookies': 20000,
    'popcorn': 12000,
    'es krim': 18000,
    'jelly': 8000,
    'air mineral': 5000,
    'teh': 8000,
    'kopi': 12000,
    'jus': 15000,
    'soda': 8000,
    'sirup': 18000,
    'minuman energi': 10000,
    'yogurt drink': 12000,
    'smoothie': 25000,
    'kue': 50000,
    'snack': 15000,
    'piring kertas': 10000,
    'gelas plastik': 8000,
    'balon': 15000,
    'dekorasi': 30000,
    'es batu': 5000,
    'serbet': 8000,
    'lilin': 10000,
    'kue ulang tahun': 150000,
    'hadiah': 100000,
    'topi pesta': 15000,
    'confetti': 12000,
    'nasi kotak': 25000,
    'tikar': 50000,
    'kantong sampah': 8000,
    'sunblock': 45000,
    'payung': 75000,
    'cooler box': 150000,
    'cemilan': 15000,
    'sayur fresh': 10000,
    'daging': 50000,
    'bumbu dapur': 20000,
    'pizza': 85000,
  };

  static String getItemPrice(String itemName) {
    final itemLower = itemName.toLowerCase();
    if (_priceDatabase.containsKey(itemLower)) {
      return formatPrice(_priceDatabase[itemLower]!);
    }
    for (final entry in _priceDatabase.entries) {
      if (itemLower.contains(entry.key) || entry.key.contains(itemLower)) {
        return formatPrice(entry.value);
      }
    }
    return formatPrice(10000); // Default price
  }

  static String formatPrice(int price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  static int parsePrice(String priceString) {
    final cleanString = priceString.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanString) ?? 0;
  }
}
