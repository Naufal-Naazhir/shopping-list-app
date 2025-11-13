import '../models/recipe_template_model.dart';
import 'template_repository.dart';

/// Contoh implementasi untuk Firebase/Appwrite
/// Ganti dengan implementasi sesuai backend yang digunakan
class RemoteTemplateRepository implements ITemplateRepository {
  // Contoh: final Appwrite _appwrite;
  // Contoh: final FirebaseFirestore _firestore;

  RemoteTemplateRepository(/* inject dependencies here */);

  @override
  Future<List<RecipeTemplate>> getAllTemplates() async {
    // Implementasi untuk mengambil data dari backend
    // Contoh untuk Firestore:
    // final snapshot = await _firestore.collection('templates').get();
    // return snapshot.docs.map((doc) => RecipeTemplate.fromJson(doc.data())).toList();
    throw UnimplementedError();
  }

  @override
  Future<List<RecipeTemplate>> getTemplatesByCategory(String category) async {
    // Contoh untuk Firestore:
    // final snapshot = await _firestore
    //     .collection('templates')
    //     .where('category', isEqualTo: category)
    //     .get();
    // return snapshot.docs.map((doc) => RecipeTemplate.fromJson(doc.data())).toList();
    throw UnimplementedError();
  }

  @override
  Future<bool> addTemplate(RecipeTemplate template) async {
    // Contoh untuk Firestore:
    // try {
    //   await _firestore.collection('templates').add(template.toJson());
    //   return true;
    // } catch (e) {
    //   return false;
    // }
    throw UnimplementedError();
  }

  @override
  Future<bool> updateTemplateUsage(String templateName) async {
    // Contoh untuk Firestore:
    // try {
    //   final snapshot = await _firestore
    //       .collection('templates')
    //       .where('name', isEqualTo: templateName)
    //       .get();
    //   if (snapshot.docs.isEmpty) return false;
    //
    //   final doc = snapshot.docs.first;
    //   await doc.reference.update({
    //     'useCount': FieldValue.increment(1),
    //     'lastUsed': FieldValue.serverTimestamp(),
    //   });
    //   return true;
    // } catch (e) {
    //   return false;
    // }
    throw UnimplementedError();
  }

  @override
  Future<List<RecipeTemplate>> getMostUsedTemplates({int limit = 5}) async {
    // Contoh untuk Firestore:
    // final snapshot = await _firestore
    //     .collection('templates')
    //     .orderBy('useCount', descending: true)
    //     .limit(limit)
    //     .get();
    // return snapshot.docs.map((doc) => RecipeTemplate.fromJson(doc.data())).toList();
    throw UnimplementedError();
  }

  @override
  Future<List<RecipeTemplate>> getRecentlyUsedTemplates({int limit = 5}) async {
    // Contoh untuk Firestore:
    // final snapshot = await _firestore
    //     .collection('templates')
    //     .orderBy('lastUsed', descending: true)
    //     .limit(limit)
    //     .get();
    // return snapshot.docs.map((doc) => RecipeTemplate.fromJson(doc.data())).toList();
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTemplate(String templateName) async {
    // Contoh untuk Firestore:
    // try {
    //   final snapshot = await _firestore
    //       .collection('templates')
    //       .where('name', isEqualTo: templateName)
    //       .get();
    //   if (snapshot.docs.isEmpty) return false;
    //
    //   await snapshot.docs.first.reference.delete();
    //   return true;
    // } catch (e) {
    //   return false;
    // }
    throw UnimplementedError();
  }

  @override
  Future<bool> clearAllTemplates() async {
    // Contoh untuk Firestore:
    // try {
    //   final batch = _firestore.batch();
    //   final snapshot = await _firestore.collection('templates').get();
    //
    //   for (var doc in snapshot.docs) {
    //     batch.delete(doc.reference);
    //   }
    //
    //   await batch.commit();
    //   return true;
    // } catch (e) {
    //   return false;
    // }
    throw UnimplementedError();
  }
}
