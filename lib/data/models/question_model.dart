import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// A single trivia question, stored at `questions/{questionId}`.
///
/// IMPORTANT: [correctAnswerIndex] must never be sent to a player before
/// they've answered. The duel flow never reads this collection directly
/// mid-round for that reason — see `duel_model.dart` / `round_model.dart`
/// and `functions/src/scoring/resolveDuel.ts`. This model is used for the
/// home_turf question-bank management screens, where showing the answer is
/// expected (you're the owner editing your own question).
class QuestionModel extends Equatable {
  const QuestionModel({
    required this.id,
    required this.categoryId,
    this.ownerId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.source,
    required this.language,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String? ownerId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final QuestionDifficulty difficulty;
  final QuestionSource source;
  final String language; // 'ar' | 'en'
  final DateTime createdAt;

  factory QuestionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuestionModel(
      id: doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      ownerId: data['ownerId'] as String?,
      questionText: data['questionText'] as String? ?? '',
      options: List<String>.from(data['options'] as List? ?? const []),
      correctAnswerIndex: (data['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      difficulty: QuestionDifficulty.fromString(data['difficulty'] as String? ?? 'medium'),
      source: QuestionSource.fromString(data['source'] as String? ?? 'api'),
      language: data['language'] as String? ?? 'ar',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    ownerId,
    questionText,
    options,
    correctAnswerIndex,
    difficulty,
    source,
    language,
    createdAt,
  ];
}
