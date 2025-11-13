import '../models/recipe_template_model.dart';
import 'template_repository.dart';

/// Repository yang menggabungkan penyimpanan lokal dan remote
/// Menyimpan data di kedua tempat dan menangani sinkronisasi
class HybridTemplateRepository implements ITemplateRepository {
  final ITemplateRepository _localRepo;
  final ITemplateRepository _remoteRepo;

  HybridTemplateRepository(this._localRepo, this._remoteRepo);

  @override
  Future<List<RecipeTemplate>> getAllTemplates() async {
    try {
      // Coba ambil dari remote dulu
      final remoteTemplates = await _remoteRepo.getAllTemplates();
      // Sync ke local
      await _syncToLocal(remoteTemplates);
      return remoteTemplates;
    } catch (e) {
      // Fallback ke local jika remote gagal
      return _localRepo.getAllTemplates();
    }
  }

  @override
  Future<List<RecipeTemplate>> getTemplatesByCategory(String category) async {
    try {
      return await _remoteRepo.getTemplatesByCategory(category);
    } catch (e) {
      return _localRepo.getTemplatesByCategory(category);
    }
  }

  @override
  Future<bool> addTemplate(RecipeTemplate template) async {
    try {
      // Simpan ke remote dulu
      final success = await _remoteRepo.addTemplate(template);
      if (success) {
        // Jika berhasil, simpan juga ke local
        await _localRepo.addTemplate(template);
      }
      return success;
    } catch (e) {
      // Jika remote gagal, simpan ke local saja
      return _localRepo.addTemplate(template);
    }
  }

  @override
  Future<bool> updateTemplateUsage(String templateName) async {
    try {
      final success = await _remoteRepo.updateTemplateUsage(templateName);
      if (success) {
        await _localRepo.updateTemplateUsage(templateName);
      }
      return success;
    } catch (e) {
      return _localRepo.updateTemplateUsage(templateName);
    }
  }

  @override
  Future<List<RecipeTemplate>> getMostUsedTemplates({int limit = 5}) async {
    try {
      return await _remoteRepo.getMostUsedTemplates(limit: limit);
    } catch (e) {
      return _localRepo.getMostUsedTemplates(limit: limit);
    }
  }

  @override
  Future<List<RecipeTemplate>> getRecentlyUsedTemplates({int limit = 5}) async {
    try {
      return await _remoteRepo.getRecentlyUsedTemplates(limit: limit);
    } catch (e) {
      return _localRepo.getRecentlyUsedTemplates(limit: limit);
    }
  }

  @override
  Future<bool> deleteTemplate(String templateName) async {
    try {
      final success = await _remoteRepo.deleteTemplate(templateName);
      if (success) {
        await _localRepo.deleteTemplate(templateName);
      }
      return success;
    } catch (e) {
      return _localRepo.deleteTemplate(templateName);
    }
  }

  @override
  Future<bool> clearAllTemplates() async {
    try {
      final success = await _remoteRepo.clearAllTemplates();
      if (success) {
        await _localRepo.clearAllTemplates();
      }
      return success;
    } catch (e) {
      return _localRepo.clearAllTemplates();
    }
  }

  /// Sinkronkan data dari remote ke local
  Future<void> _syncToLocal(List<RecipeTemplate> remoteTemplates) async {
    await _localRepo.clearAllTemplates();
    for (var template in remoteTemplates) {
      await _localRepo.addTemplate(template);
    }
  }

  /// Sinkronkan data dari local ke remote
  /// Berguna saat aplikasi online kembali setelah offline
  Future<void> syncToRemote() async {
    final localTemplates = await _localRepo.getAllTemplates();
    for (var template in localTemplates) {
      await _remoteRepo.addTemplate(template);
    }
  }
}
