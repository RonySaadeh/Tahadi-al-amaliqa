import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A row in the global leaderboard. This is just a read-friendly view over
/// [UserModel] fields (see `leaderboard_repository.dart`, which queries
/// `users` ordered by `elo` directly — there's no separate global-ranking
/// collection since a simple ordered query is plenty at this app's scale).
class LeaderboardEntryModel extends Equatable {
  const LeaderboardEntryModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.elo,
    required this.wins,
    required this.losses,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final int elo;
  final int wins;
  final int losses;

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LeaderboardEntryModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      elo: (data['elo'] as num?)?.toInt() ?? 0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [uid, displayName, photoUrl, elo, wins, losses];
}

/// A head-to-head record between exactly two players, stored at
/// `leaderboardPairings/{pairingId}` (see `FirestorePaths.pairingId`).
/// Updated atomically by `resolveDuel` whenever a duel between this pair
/// completes, so reading it is a single cheap document fetch instead of
/// scanning every past duel.
class HeadToHeadRecordModel extends Equatable {
  const HeadToHeadRecordModel({
    required this.pairingId,
    required this.playerAId,
    required this.playerBId,
    this.playerAWins = 0,
    this.playerBWins = 0,
    this.lastDuelAt,
  });

  final String pairingId;
  final String playerAId;
  final String playerBId;
  final int playerAWins;
  final int playerBWins;
  final DateTime? lastDuelAt;

  int winsFor(String uid) => uid == playerAId ? playerAWins : playerBWins;
  int lossesFor(String uid) => uid == playerAId ? playerBWins : playerAWins;

  factory HeadToHeadRecordModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return HeadToHeadRecordModel(
      pairingId: doc.id,
      playerAId: data['playerAId'] as String? ?? '',
      playerBId: data['playerBId'] as String? ?? '',
      playerAWins: (data['playerAWins'] as num?)?.toInt() ?? 0,
      playerBWins: (data['playerBWins'] as num?)?.toInt() ?? 0,
      lastDuelAt: (data['lastDuelAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [pairingId, playerAId, playerBId, playerAWins, playerBWins, lastDuelAt];
}
