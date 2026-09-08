import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/category_model.dart';
import '../../data/models/question_model.dart';

/// Managing a player's own "home turf" categories and questions. All writes
/// go through Cloud Functions (`createHomeTurfCategory`,
/// `addHomeTurfQuestion`, `generateQuestions`) — see
/// `data/repositories/question_repository.dart` — because categories and
/// questions are client-read-only collections (anyone could otherwise plant
/// a rigged question). The 3-category limit is enforced server-side too;
/// [myCategoriesProvider]'s length is only used here to disable the "new
/// category" button early for a nicer UX, not as the actual guard.
class HomeTurfController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> createCategory({required String name, required String description}) async {
    state = const AsyncValue.loading();
    String? categoryId;
    state = await AsyncValue.guard(() async {
      categoryId = await ref
          .read(questionRepositoryProvider)
          .createHomeTurfCategory(name: name, description: description);
    });
    return categoryId;
  }

  Future<void> addQuestion({
    required String categoryId,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    required String difficulty,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(questionRepositoryProvider)
          .addHomeTurfQuestion(
            categoryId: categoryId,
            questionText: questionText,
            options: options,
            correctAnswerIndex: correctAnswerIndex,
            difficulty: difficulty,
          );
    });
  }

  Future<int> generateWithAI({
    required String categoryId,
    required String topic,
    required String difficulty,
    required String language,
    int count = 10,
  }) async {
    state = const AsyncValue.loading();
    int created = 0;
    state = await AsyncValue.guard(() async {
      created = await ref
          .read(questionRepositoryProvider)
          .generateQuestionsWithAI(
            categoryId: categoryId,
            topic: topic,
            difficulty: difficulty,
            language: language,
            count: count,
          );
    });
    return created;
  }
}

final homeTurfControllerProvider = NotifierProvider<HomeTurfController, AsyncValue<void>>(
  HomeTurfController.new,
);

final myCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(questionRepositoryProvider).watchCategoriesOwnedBy(uid);
});

final categoryQuestionsProvider = StreamProvider.family<List<QuestionModel>, String>((ref, categoryId) {
  return ref.watch(questionRepositoryProvider).watchQuestionsForCategory(categoryId);
});

bool canCreateAnotherCategory(int currentCount) => currentCount < AppConstants.maxHomeTurfCategories;
