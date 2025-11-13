import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe_template_model.dart';
import 'template_repository.dart';

class LocalTemplateRepository implements ITemplateRepository {
  final SharedPreferences _prefs;
  static const String _templatesKey = 'recipe_templates';

  LocalTemplateRepository(this._prefs);

  @override
  Future<List<RecipeTemplate>> getAllTemplates() async {
    final String? jsonStr = _prefs.getString(_templatesKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((json) => RecipeTemplate.fromJson(json)).toList();
  }

  @override
  Future<List<RecipeTemplate>> getTemplatesByCategory(String category) async {
    final templates = await getAllTemplates();
    return templates
        .where((template) => template.category == category)
        .toList();
  }

  @override
  Future<bool> addTemplate(RecipeTemplate template) async {
    final templates = await getAllTemplates();

    if (templates.any((t) => t.name == template.name)) {
      return false;
    }

    templates.add(template);
    return await _saveTemplates(templates);
  }

  @override
  Future<bool> updateTemplateUsage(String templateName) async {
    final templates = await getAllTemplates();
    final index = templates.indexWhere((t) => t.name == templateName);

    if (index == -1) return false;

    templates[index].useCount++;
    templates[index].lastUsed = DateTime.now();

    return await _saveTemplates(templates);
  }

  @override
  Future<List<RecipeTemplate>> getMostUsedTemplates({int limit = 5}) async {
    final templates = await getAllTemplates();
    templates.sort((a, b) => b.useCount.compareTo(a.useCount));
    return templates.take(limit).toList();
  }

  @override
  Future<List<RecipeTemplate>> getRecentlyUsedTemplates({int limit = 5}) async {
    final templates = await getAllTemplates();
    templates.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return templates.take(limit).toList();
  }

  @override
  Future<bool> deleteTemplate(String templateName) async {
    final templates = await getAllTemplates();
    templates.removeWhere((t) => t.name == templateName);
    return await _saveTemplates(templates);
  }

  @override
  Future<bool> clearAllTemplates() async {
    return await _prefs.remove(_templatesKey);
  }

  Future<bool> _saveTemplates(List<RecipeTemplate> templates) async {
    final jsonList = templates.map((t) => t.toJson()).toList();
    return await _prefs.setString(_templatesKey, json.encode(jsonList));
  }
}
