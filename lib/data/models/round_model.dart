import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// One round of a duel, stored at `duels/{duelId}/rounds/{roundNumber}`.
///
/// While [status] is [RoundStatus.active] this document deliberately does
/// NOT contain `correctAnswerIndex` or either player's answer — those only
/// appear once the round is [RoundStatus.resolved], written by the
/// `submitAnswer`/round-resolution Cloud Function. This is what stops a
/// player from reading the answer key out of Firestore mid-round.
class RoundModel extends Equatable {
  const RoundModel({
    required this.roundNumber,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.difficulty,
    required this.status,
    this.correctAnswerIndex,
    this.playerAnswers = const {},
    this.pointsAwarded = const {},
    required this.startedAt,
  });

  final int roundNumber;
  final String questionId;
  final String questionText;
  final List<String> options;
  final QuestionDifficulty difficulty;
  final RoundStatus status;

  /// Only present once [status] is [RoundStatus.resolved].
  final int? correctAnswerIndex;

  /// uid -> selected option index. Only present once resolved.
  final Map<String, int> playerAnswers;

  /// uid -> points earned this round. Only present once resolved.
  final Map<String, int> pointsAwarded;

  final DateTime startedAt;

  bool get isResolved => status == RoundStatus.resolved;

  factory RoundModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return RoundModel(
      roundNumber: (data['roundNumber'] as num?)?.toInt() ?? int.parse(doc.id),
      questionId: data['questionId'] as String? ?? '',
      questionText: data['questionText'] as String? ?? '',
      options: List<String>.from(data['options'] as List? ?? const []),
      difficulty: QuestionDifficulty.fromString(data['difficulty'] as String? ?? 'medium'),
      status: RoundStatus.fromString(data['status'] as String? ?? 'active'),
      correctAnswerIndex: (data['correctAnswerIndex'] as num?)?.toInt(),
      playerAnswers: Map<String, int>.from(data['playerAnswers'] as Map? ?? const {}),
      pointsAwarded: Map<String, int>.from(data['pointsAwarded'] as Map? ?? const {}),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    roundNumber,
    questionId,
    questionText,
    options,
    difficulty,
    status,
    correctAnswerIndex,
    playerAnswers,
    pointsAwarded,
    startedAt,
  ];
}
