import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/recipe_template_model.dart';

class TemplateManager {
  final SharedPreferences _prefs;
  static const String _templatesKey = 'recipe_templates';

  TemplateManager(this._prefs);

  // Get all templates
  List<RecipeTemplate> getAllTemplates() {
    final String? jsonStr = _prefs.getString(_templatesKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((json) => RecipeTemplate.fromJson(json)).toList();
  }

  // Get templates by category
  List<RecipeTemplate> getTemplatesByCategory(String category) {
    return getAllTemplates()
        .where((template) => template.category == category)
        .toList();
  }

  // Add new template
  Future<bool> addTemplate(RecipeTemplate template) async {
    final templates = getAllTemplates();

    // Check for duplicates
    if (templates.any((t) => t.name == template.name)) {
      return false;
    }

    templates.add(template);
    return await saveTemplates(templates);
  }

  // Update template usage
  Future<bool> updateTemplateUsage(String templateName) async {
    final templates = getAllTemplates();
    final index = templates.indexWhere((t) => t.name == templateName);

    if (index == -1) return false;

    templates[index].useCount++;
    templates[index].lastUsed = DateTime.now();

    return await saveTemplates(templates);
  }

  // Get most used templates
  List<RecipeTemplate> getMostUsedTemplates({int limit = 5}) {
    final templates = getAllTemplates();
    templates.sort((a, b) => b.useCount.compareTo(a.useCount));
    return templates.take(limit).toList();
  }

  // Get recently used templates
  List<RecipeTemplate> getRecentlyUsedTemplates({int limit = 5}) {
    final templates = getAllTemplates();
    templates.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return templates.take(limit).toList();
  }

  // Save templates to storage
  Future<bool> saveTemplates(List<RecipeTemplate> templates) async {
    final jsonList = templates.map((t) => t.toJson()).toList();
    return await _prefs.setString(_templatesKey, json.encode(jsonList));
  }

  // Delete template
  Future<bool> deleteTemplate(String templateName) async {
    final templates = getAllTemplates();
    templates.removeWhere((t) => t.name == templateName);
    return await saveTemplates(templates);
  }

  // Clear all templates
  Future<bool> clearAllTemplates() async {
    return await _prefs.remove(_templatesKey);
  }
}
