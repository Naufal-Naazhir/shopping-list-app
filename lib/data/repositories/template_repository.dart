import '../models/recipe_template_model.dart';

abstract class ITemplateRepository {
  Future<List<RecipeTemplate>> getAllTemplates();
  Future<List<RecipeTemplate>> getTemplatesByCategory(String category);
  Future<List<RecipeTemplate>> getMostUsedTemplates({int limit = 5});
  Future<List<RecipeTemplate>> getRecentlyUsedTemplates({int limit = 5});
  Future<bool> addTemplate(RecipeTemplate template);
  Future<bool> updateTemplateUsage(String templateName);
  Future<bool> deleteTemplate(String templateName);
  Future<bool> clearAllTemplates();
}
