import '../data/models/recipe_template_model.dart';
import '../data/repositories/template_repository.dart';

class TemplateManager {
  final ITemplateRepository _repository;

  TemplateManager(this._repository);

  // Get all templates
  Future<List<RecipeTemplate>> getAllTemplates() {
    return _repository.getAllTemplates();
  }

  // Get templates by category
  Future<List<RecipeTemplate>> getTemplatesByCategory(String category) {
    return _repository.getTemplatesByCategory(category);
  }

  // Add new template
  Future<bool> addTemplate(RecipeTemplate template) {
    return _repository.addTemplate(template);
  }

  // Update template usage
  Future<bool> updateTemplateUsage(String templateName) {
    return _repository.updateTemplateUsage(templateName);
  }

  // Get most used templates
  Future<List<RecipeTemplate>> getMostUsedTemplates({int limit = 5}) {
    return _repository.getMostUsedTemplates(limit: limit);
  }

  // Get recently used templates
  Future<List<RecipeTemplate>> getRecentlyUsedTemplates({int limit = 5}) {
    return _repository.getRecentlyUsedTemplates(limit: limit);
  }

  // Delete template
  Future<bool> deleteTemplate(String templateName) {
    return _repository.deleteTemplate(templateName);
  }

  // Clear all templates
  Future<bool> clearAllTemplates() {
    return _repository.clearAllTemplates();
  }
}
