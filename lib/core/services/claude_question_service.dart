import 'cloud_functions_service.dart';

/// Feature-facing wrapper around the `generateQuestions` Cloud Function.
///
/// Kept separate from [CloudFunctionsService] (which just forwards raw
/// callable requests) because this is the piece product logic — the
/// home_turf feature — actually talks to. The client NEVER calls the
/// Claude API directly: the API key only ever lives in the Cloud Function's
/// environment. See `functions/src/questions/generateQuestions.ts`.
class ClaudeQuestionService {
  ClaudeQuestionService({CloudFunctionsService? cloudFunctions})
    : _cloudFunctions = cloudFunctions ?? CloudFunctionsService();

  final CloudFunctionsService _cloudFunctions;

  /// Requests a batch of AI-generated questions for [categoryId] on
  /// [topic]. Returns the number of questions actually written (the
  /// function validates the LLM's JSON shape and drops anything malformed,
  /// so this can be less than [count]).
  Future<int> generateForCategory({
    required String categoryId,
    required String topic,
    required String difficulty,
    required String language,
    int count = 10,
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
