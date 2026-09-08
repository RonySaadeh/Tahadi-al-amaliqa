import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';

/// Reads categories/questions, and forwards home-turf writes to their
/// Cloud Functions (categories and questions are client-read-only — see
/// `firestore.rules` — so creation always goes through
/// [CloudFunctionsService]).
class QuestionRepository {
  QuestionRepository({FirestoreService? firestoreService, CloudFunctionsService? cloudFunctions})
    : _firestore = firestoreService ?? FirestoreService(),
      _cloudFunctions = cloudFunctions ?? CloudFunctionsService();

  final FirestoreService _firestore;
  final CloudFunctionsService _cloudFunctions;

  Stream<List<CategoryModel>> watchAllCategories() {
    return _firestore.categories
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  Stream<List<CategoryModel>> watchCategoriesOwnedBy(String uid) {
    return _firestore.categories
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  Stream<List<QuestionModel>> watchQuestionsForCategory(String categoryId) {
    return _firestore.questions
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(QuestionModel.fromFirestore).toList());
  }

  Future<String> createHomeTurfCategory({required String name, required String description}) {
    return _cloudFunctions.createHomeTurfCategory(name: name, description: description);
  }

  Future<void> addHomeTurfQuestion({
    required String categoryId,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    required String difficulty,
  }) {
    return _cloudFunctions.addHomeTurfQuestion(
      categoryId: categoryId,
      questionText: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      difficulty: difficulty,
    );
  }

  Future<int> generateQuestionsWithAI({
    required String categoryId,
    required String topic,
    required String difficulty,
    required String language,
    required int count,
  }) {
    return _cloudFunctions.generateQuestions(
      categoryId: categoryId,
      topic: topic,
      difficulty: difficulty,
      count: count,
      language: language,
    );
  }
}
