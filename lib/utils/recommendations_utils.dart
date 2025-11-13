import 'package:flutter/material.dart';

class RecommendationsUtils {
  static final Map<String, List<String>> _recommendations = {
    'supermarket': [
      'Beras 5kg',
      'Minyak Goreng 2L',
      'Gula Pasir 1kg',
      'Telur 1kg',
      'Susu UHT',
      'Roti Tawar',
      'Sabun Mandi',
      'Deterjen',
      'Shampo',
      'Pasta Gigi',
    ],
    'shopping': [
      'Beras',
      'Minyak Goreng',
      'Gula',
      'Telur',
      'Susu',
      'Roti',
      'Sabun',
      'Shampo',
      'Tisu',
      'Pasta Gigi',
    ],
    'groceries': [
      'Sayur Bayam',
      'Wortel',
      'Kentang',
      'Bawang Merah',
      'Bawang Putih',
      'Cabai',
      'Tomat',
      'Daging Ayam',
      'Ikan',
      'Tempe',
    ],
    'market': [
      'Ikan Segar',
      'Sayur Kangkung',
      'Tempe',
      'Tahu',
      'Cabai Rawit',
      'Jahe',
      'Kunyit',
      'Lengkuas',
      'Daun Salam',
      'Serai',
    ],
    'breakfast': [
      'Roti',
      'Selai',
      'Mentega',
      'Susu',
      'Sereal',
      'Telur',
      'Keju',
      'Yogurt',
      'Oatmeal',
      'Madu',
    ],
    'lunch': [
      'Nasi',
      'Ayam',
      'Sayur',
      'Sambal',
      'Lauk Pauk',
      'Tempe',
      'Tahu',
      'Ikan',
      'Sop',
      'Kerupuk',
    ],
    'dinner': [
      'Nasi',
      'Lauk',
      'Sayur',
      'Buah',
      'Sup',
      'Salad',
      'Protein',
      'Karbohidrat',
      'Minuman',
      'Dessert',
    ],
    'snack': [
      'Keripik',
      'Coklat',
      'Biskuit',
      'Permen',
      'Kacang',
      'Wafer',
      'Cookies',
      'Popcorn',
      'Es Krim',
      'Jelly',
    ],
    'drink': [
      'Air Mineral',
      'Teh',
      'Kopi',
      'Jus',
      'Soda',
      'Susu',
      'Sirup',
      'Minuman Energi',
      'Yogurt Drink',
      'Smoothie',
    ],
    'party': [
      'Kue',
      'Minuman',
      'Snack',
      'Piring Kertas',
      'Gelas Plastik',
      'Balon',
      'Dekorasi',
      'Es Batu',
      'Serbet',
      'Lilin',
    ],
    'birthday': [
      'Kue Ulang Tahun',
      'Lilin',
      'Balon',
      'Piring',
      'Minuman',
      'Snack',
      'Hadiah',
      'Dekorasi',
      'Topi Pesta',
      'Confetti',
    ],
    'picnic': [
      'Nasi Kotak',
      'Air Mineral',
      'Buah',
      'Snack',
      'Tikar',
      'Tisu',
      'Kantong Sampah',
      'Sunblock',
      'Payung',
      'Cooler Box',
    ],
    'weekend': [
      'Cemilan',
      'Minuman',
      'Buah',
      'Sayur Fresh',
      'Daging',
      'Bumbu Dapur',
      'Snack',
      'Dessert',
      'Es Krim',
      'Pizza',
    ],
    'default': [
      'Beras',
      'Minyak',
      'Gula',
      'Telur',
      'Sayur',
      'Buah',
      'Daging',
      'Ikan',
      'Susu',
      'Roti',
    ],
  };

  static List<String> getRecommendations(String listName) {
    final lowerCaseListName = listName.toLowerCase();
    for (final entry in _recommendations.entries) {
      if (lowerCaseListName.contains(entry.key) ||
          entry.key.contains(lowerCaseListName)) {
        return entry.value;
      }
    }
    return _recommendations['default']!;
  }

  static final Map<String, Color> _suggestionColors = {
    'Supermarket': const Color(0xFF4CAF50),
    'Shopping': const Color(0xFF2196F3),
    'Groceries': const Color(0xFF8BC34A),
    'Breakfast': const Color(0xFFFFA500),
    'Lunch': const Color(0xFFFF5722),
    'Dinner': const Color(0xFF9C27B0),
    'Snack': const Color(0xFFFFC107),
    'Drink': const Color(0xFF00BCD4),
    'Party': const Color(0xFFE91E63),
    'Birthday': const Color(0xFFF44336),
    'Picnic': const Color(0xFF795548),
    'Weekend': const Color(0xFF009688),
    'Market': const Color(0xFF607D8B),
  };

  static Color getSuggestionColor(String name) {
    return _suggestionColors[name] ?? Colors.grey;
  }

  static final Map<String, String> _suggestionEmojis = {
    'Supermarket': '🛒',
    'Shopping': '🛍️',
    'Groceries': '🥬',
    'Breakfast': '🍳',
    'Lunch': '🍱',
    'Dinner': '🍽️',
    'Snack': '🍿',
    'Drink': '🥤',
    'Party': '🎉',
    'Birthday': '🎂',
    'Picnic': '🧺',
    'Weekend': '🌴',
    'Market': '🏪',
  };

  static String getSuggestionEmoji(String name) {
    return _suggestionEmojis[name] ?? '✨';
  }
}
