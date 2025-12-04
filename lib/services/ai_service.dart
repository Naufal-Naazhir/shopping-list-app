import 'dart:async';
import 'dart:convert';

import 'package:belanja_praktis/services/local_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/recipe_template_model.dart';
// Import ShoppingItem model
import '../data/models/shopping_list_model.dart';
import '../data/repositories/local_template_repository.dart';
import 'template_manager_new.dart' as tm;

class AIService {
  // API configuration - Loaded from environment variables
  final String _apiKey = dotenv.get('COHERE_API_KEY');
  late final String _endpoint;

  final http.Client _client;
  final LocalStorageService _storage;
  late final tm.TemplateManager _templateManager;

  static const Duration _timeout = Duration(seconds: 30);

  AIService(this._storage) : _client = http.Client() {
    try {
      _endpoint = dotenv.get('COHERE_ENDPOINT');
      if (_apiKey.isEmpty) {
        throw Exception('COHERE_API_KEY is not set in the .env file.');
      }
    } catch (e) {
      throw Exception('Failed to load environment variables: $e');
    }
    SharedPreferences.getInstance().then((prefs) {
      final localRepo = LocalTemplateRepository(prefs);
      _templateManager = tm.TemplateManager(localRepo);
    });
  }

  void dispose() {
    _client.close();
  }

  // Helper method to parse the raw JSON from AI into structured data
  Map<String, dynamic> _parseAIResponse(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      final List<dynamic> itemMaps =
          decoded['items'] ?? []; // Default to empty list
      final List<dynamic> stepsList =
          decoded['steps'] ?? []; // Safely get steps
      double total = double.tryParse(decoded['total'].toString()) ?? 0.0;

      List<ShoppingItem> shoppingItems = [];
      for (var itemJson in itemMaps) {
        shoppingItems.add(
          ShoppingItem(
            id: '', // Firestore will generate this ID
            name: itemJson['name'] as String,
            quantity: int.tryParse(itemJson['quantity'].toString()) ?? 1,
            price: double.tryParse(itemJson['price'].toString()) ?? 0.0,
            isBought: false,
          ),
        );
      }

      List<String> steps = stepsList.map((e) => e.toString()).toList();

      return {'items': shoppingItems, 'total': total, 'steps': steps};
    } catch (e) {
      // If parsing fails, throw a more informative error
      throw Exception(
        'Failed to parse JSON from AI. Raw response: "$jsonString"',
      );
    }
  }

  Future<Map<String, dynamic>> _generateFromAI(String query) async {
    String prompt;
    final queryLower = query.toLowerCase();
    final recipeKeywords = [
      'resep',
      'bahan',
      'langkah',
      'cara membuat',
      'recipe',
      'ingredients',
      'steps',
      'how to make',
    ];

    if (recipeKeywords.any((keyword) => queryLower.contains(keyword))) {
      // Use the detailed recipe prompt
      prompt =
          '''Berikan daftar belanja DAN langkah-langkah pembuatan untuk resep "$query" berdasarkan versi yang paling umum dan otentik.
Format JSON:{"items":[{"name":"nama_item","quantity":"jumlah","unit":"satuan","price":harga}],"total":total_harga,"steps":["langkah 1","langkah 2"]}
Aturan: Sertakan hanya bahan-bahan yang relevan. Satuan harus salah satu dari: gram, kg, butir, siung, sdm, sdt, ml, liter, buah, batang, lembar. Harga dalam Rupiah tanpa simbol atau pemisah. Respons HANYA JSON.''';
    } else {
      // Use a more general shopping list prompt
      prompt = '''Berikan daftar belanja untuk "$query".
Format JSON:{"items":[{"name":"nama_item","quantity":"jumlah","unit":"satuan","price":harga}],"total":total_harga}
Aturan: Satuan harus umum (misal: buah, kg, pack). Harga dalam Rupiah tanpa simbol atau pemisah. Respons HANYA JSON.''';
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'message': prompt,
              'model': 'command-nightly',
              'temperature': 0.3,
              'preamble':
                  'You are a helpful assistant that provides shopping list information in JSON format.',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['text'] != null) {
          final rawString = data['text'].trim();
          final startIndex = rawString.indexOf('{');
          final endIndex = rawString.lastIndexOf('}');

          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            final cleanJsonString = rawString.substring(
              startIndex,
              endIndex + 1,
            );
            await _storage.saveRecipeCache(query, cleanJsonString);
            return _parseAIResponse(cleanJsonString);
          } else {
            throw Exception(
              'Could not find a valid JSON object in the AI response.',
            );
          }
        } else {
          throw Exception('AI response does not contain "text" field.');
        }
      } else {
        throw Exception(
          'Error from AI Service: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to generate from AI: $e');
    }
  }

  /// Membuat daftar belanja dari resep atau kueri umum
  Future<Map<String, dynamic>> generateShoppingList(String query) async {
    try {
      final cachedJsonString = await _storage.getRecipeCache(query);
      if (cachedJsonString != null) {
        return _parseAIResponse(cachedJsonString);
      }

      final aiResult = await _generateFromAI(query);

      await _templateManager.addTemplate(
        RecipeTemplate(name: query, category: 'Other'),
      );

      return aiResult;
    } catch (e) {
      throw Exception('Gagal membuat daftar belanja: $e');
    }
  }

  /// Mendapatkan daftar template resep populer
  Future<List<RecipeTemplate>> getPopularTemplates() {
    return _templateManager.getMostUsedTemplates();
  }

  /// Menambahkan resep ke template
  Future<void> addToTemplates(
    String recipe, {
    String category = 'Other',
  }) async {
    await _templateManager.addTemplate(
      RecipeTemplate(name: recipe, category: category),
    );
  }
}
