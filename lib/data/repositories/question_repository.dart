import '../../core/services/firestore_service.dart';
import '../models/category_group_model.dart';
import '../models/category_model.dart';

/// Reads categories — client-read-only (see `firestore.rules`), seeded
/// entirely server-side by the `functions/src/seed` admin scripts.
class QuestionRepository {
  QuestionRepository({FirestoreService? firestoreService}) : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  Stream<List<CategoryModel>> watchAllCategories() {
    return _firestore.categories
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  /// The section headers the category picker groups categories under (see
  /// `functions/src/seed/categoryTaxonomy.ts`). Small, static-ish list — a
  /// single unfiltered read is plenty at this app's scale.
  Stream<List<CategoryGroupModel>> watchCategoryGroups() {
    return _firestore.categoryGroups.orderBy('order').snapshots().map(
      (snap) => snap.docs.map(CategoryGroupModel.fromFirestore).toList(),
    );
  }

}
