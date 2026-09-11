import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// A single 1v1 duel, stored at `duels/{duelId}` with a `rounds`
/// subcollection (see [RoundModel]). Every duel gets its own document and
/// subcollection so concurrent duels never share reads/writes — see the
/// architecture note in `features/duel/README.md`.
///
/// Entirely written by Cloud Functions (`createDuel` on creation,
/// round-resolution + `resolveDuel` logic as it progresses). The client only
/// ever reads/listens to this document.
class DuelModel extends Equatable {
  const DuelModel({
    required this.id,
    required this.player1Id,
    required this.player2Id,
    this.player1DisplayName = '',
    this.player2DisplayName = '',
    required this.categoryId,
    required this.categoryName,
    this.language = 'ar',
    this.isHomeTurfDuel = false,
    this.homeTurfOwnerId,
    required this.status,
    this.player1Score = 0,
    this.player2Score = 0,
    required this.currentRound,
    required this.totalRounds,
    this.winnerId,
    this.eloChange = const {},
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.player1LastSeenAt,
    this.player2LastSeenAt,
  });

  final String id;
  final String player1Id;
  final String player2Id;
  final String player1DisplayName;
  final String player2DisplayName;
  final String categoryId;
  final String categoryName;

  /// The language both rounds' question text/options are in, fixed for the
  /// whole duel by whoever started it. `'ar'` or `'en'`.
  final String language;
  final bool isHomeTurfDuel;
  final String? homeTurfOwnerId;
  final DuelStatus status;
  final int player1Score;
  final int player2Score;
  final int currentRound;
  final int totalRounds;

  /// Null until the duel is completed. Empty string is used for a draw.
  final String? winnerId;

  /// uid -> ELO delta applied by `resolveDuel`. Empty until completed.
  final Map<String, int> eloChange;

  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Last time each player's client called the `heartbeat` Cloud Function
  /// while this duel was active — see `DuelPresenceController`. Null until
  /// their first heartbeat.
  final DateTime? player1LastSeenAt;
  final DateTime? player2LastSeenAt;

  String opponentIdFor(String uid) => uid == player1Id ? player2Id : player1Id;

  String opponentDisplayNameFor(String uid) => uid == player1Id ? player2DisplayName : player1DisplayName;

  int scoreFor(String uid) => uid == player1Id ? player1Score : player2Score;

  /// The other player's last known heartbeat, from the perspective of [uid].
  /// Null if they haven't sent one yet (e.g. right after the duel started).
  DateTime? opponentLastSeenAtFor(String uid) =>
      uid == player1Id ? player2LastSeenAt : player1LastSeenAt;

  bool get isFinished => status == DuelStatus.completed || status == DuelStatus.cancelled;

  factory DuelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DuelModel(
      id: doc.id,
      player1Id: data['player1Id'] as String? ?? '',
      player2Id: data['player2Id'] as String? ?? '',
      player1DisplayName: data['player1DisplayName'] as String? ?? '',
      player2DisplayName: data['player2DisplayName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      language: data['language'] as String? ?? 'ar',
      isHomeTurfDuel: data['isHomeTurfDuel'] as bool? ?? false,
      homeTurfOwnerId: data['homeTurfOwnerId'] as String?,
      status: DuelStatus.fromString(data['status'] as String? ?? 'pending'),
      player1Score: (data['player1Score'] as num?)?.toInt() ?? 0,
      player2Score: (data['player2Score'] as num?)?.toInt() ?? 0,
      currentRound: (data['currentRound'] as num?)?.toInt() ?? 1,
      totalRounds: (data['totalRounds'] as num?)?.toInt() ?? 5,
      winnerId: data['winnerId'] as String?,
      eloChange: Map<String, int>.from(data['eloChange'] as Map? ?? const {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      player1LastSeenAt: (data['player1LastSeenAt'] as Timestamp?)?.toDate(),
      player2LastSeenAt: (data['player2LastSeenAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    player1Id,
    player2Id,
    categoryId,
    language,
    isHomeTurfDuel,
    status,
    player1Score,
    player2Score,
    currentRound,
    totalRounds,
    winnerId,
    eloChange,
    createdAt,
    startedAt,
    completedAt,
    // Load-bearing: a heartbeat is often the *only* field that changes
    // between two snapshots of an active duel. Leaving these out made those
    // snapshots compare equal, so `duelStreamProvider` deduplicated them
    // away and `DuelPresenceController` read a permanently frozen
    // `lastSeenAt` — making both players look disconnected to each other.
    player1LastSeenAt,
    player2LastSeenAt,
  ];
}
