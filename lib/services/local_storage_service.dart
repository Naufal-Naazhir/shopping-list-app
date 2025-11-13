import 'dart:convert';

import 'package:flutter/material.dart'; // New import
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/recipe_cache_model.dart';
import '../data/models/recipe_template_model.dart';
import '../services/template_manager.dart';

class LocalStorageService {
  final Logger _logger = Logger();
  static const String _cacheKey = 'recipe_cache';
  final SharedPreferences _prefs;

  static const String _themeModeKey = 'theme_mode';

  LocalStorageService(this._prefs);

  // Theme Mode methods
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.toString());
  }

  ThemeMode getThemeMode() {
    final String? themeModeString = _prefs.getString(_themeModeKey);
    if (themeModeString == ThemeMode.light.toString()) {
      return ThemeMode.light;
    } else if (themeModeString == ThemeMode.dark.toString()) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system; // Default to system
    }
  }

  // Template resep default
  static const List<Map<String, String>> defaultTemplates = [
    {'name': 'Nasi Goreng', 'category': 'Makanan Utama'},
    {'name': 'Rendang', 'category': 'Makanan Utama'},
    {'name': 'Soto Ayam', 'category': 'Makanan Utama'},
    {'name': 'Gado-gado', 'category': 'Makanan Ringan'},
    {'name': 'Sate Ayam', 'category': 'Makanan Ringan'},
  ];

  Future<void> saveRecipeCache(String recipe, String result) async {
    if (recipe.isEmpty || result.isEmpty) {
      _logger.w('Mencoba menyimpan recipe/result kosong');
      throw ArgumentError('Recipe dan result tidak boleh kosong');
    }

    try {
      final cache = RecipeCache(
        recipe: recipe,
        result: result,
        timestamp: DateTime.now(),
      );

      final cacheData = _prefs.getString(_cacheKey);
      Map<String, dynamic> cacheMap;

      if (cacheData != null) {
        try {
          cacheMap = json.decode(cacheData) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Error parsing cache data: $e');
          cacheMap = {};
        }
      } else {
        cacheMap = {};
      }

      cacheMap[recipe] = cache.toJson();
      final success = await _prefs.setString(_cacheKey, json.encode(cacheMap));

      if (!success) {
        _logger.e('Gagal menyimpan cache untuk recipe: $recipe');
        throw Exception('Gagal menyimpan cache');
      }

      _logger.i('Cache berhasil disimpan untuk recipe: $recipe');
    } catch (e) {
      _logger.e('Error saat menyimpan cache: $e');
      rethrow;
    }
  }

  Future<String?> getRecipeCache(String recipe) async {
    try {
      if (recipe.isEmpty) {
        _logger.w('Mencoba mengambil cache dengan recipe kosong');
        return null;
      }

      final cacheData = _prefs.getString(_cacheKey);
      if (cacheData != null) {
        try {
          final cacheMap = json.decode(cacheData) as Map<String, dynamic>;
          if (cacheMap.containsKey(recipe)) {
            try {
              final cache = RecipeCache.fromJson(cacheMap[recipe]);
              // Cek apakah cache masih valid (kurang dari 7 hari)
              if (DateTime.now().difference(cache.timestamp).inDays < 7) {
                _logger.i('Cache hit untuk recipe: $recipe');
                return cache.result;
              } else {
                _logger.d('Cache expired untuk recipe: $recipe');
                await _removeExpiredCache(recipe);
              }
            } catch (e) {
              _logger.e(
                'Gagal parsing cache untuk recipe: $recipe. Error: $e. Menghapus cache yang rusak.',
              );
              await _removeExpiredCache(recipe); // Hapus cache yang rusak
            }
          }
        } catch (e) {
          _logger.e('Error parsing cache data: $e');
        }
      }
      _logger.d('Cache miss untuk recipe: $recipe');
      return null;
    } catch (e) {
      _logger.e('Error saat mengambil cache: $e');
      return null;
    }
  }

  Future<void> _removeExpiredCache(String recipe) async {
    try {
      final cacheData = _prefs.getString(_cacheKey);
      if (cacheData != null) {
        final cacheMap = json.decode(cacheData) as Map<String, dynamic>;
        cacheMap.remove(recipe);
        await _prefs.setString(_cacheKey, json.encode(cacheMap));
        _logger.i('Expired cache removed untuk recipe: $recipe');
      }
    } catch (e) {
      _logger.e('Error saat menghapus expired cache: $e');
    }
  }

  Future<void> initializeDefaultTemplates() async {
    try {
      final templateManager = TemplateManager(_prefs);
      final existingTemplates = templateManager.getAllTemplates();

      if (existingTemplates.isEmpty) {
        for (final template in defaultTemplates) {
          await templateManager.addTemplate(
            RecipeTemplate(
              name: template['name']!,
              category: template['category']!,
            ),
          );
        }
        _logger.i('Template default ditambahkan');
      }
    } catch (e) {
      _logger.e('Error saat menginisialisasi template default: $e');
    }
  }

  Future<void> cleanupExpiredCache() async {
    try {
      final cacheData = _prefs.getString(_cacheKey);
      if (cacheData != null) {
        final cacheMap = json.decode(cacheData) as Map<String, dynamic>;
        final now = DateTime.now();

        cacheMap.removeWhere((key, value) {
          final cache = RecipeCache.fromJson(value);
          return now.difference(cache.timestamp).inDays >= 7;
        });

        await _prefs.setString(_cacheKey, json.encode(cacheMap));
        _logger.i('Cleanup expired cache selesai');
      }
    } catch (e) {
      _logger.e('Error saat cleanup expired cache: $e');
    }
  }
}
