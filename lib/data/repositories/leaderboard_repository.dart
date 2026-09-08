import '../../core/constants/firestore_paths.dart';
import '../../core/services/firestore_service.dart';
import '../models/leaderboard_entry_model.dart';

/// Reads the global ranking and head-to-head records.
///
/// Both are pre-computed: the global ranking is just `users` ordered by
/// `elo` (cheap at this app's scale — dozens to low hundreds of users, not
/// millions), and head-to-head records are maintained incrementally by the
/// `resolveDuel` Cloud Function writing to `leaderboardPairings/{pairingId}`
/// on every completed duel, rather than this repository scanning duel
/// history on every read.
class LeaderboardRepository {
  LeaderboardRepository({FirestoreService? firestoreService})
    : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  Stream<List<LeaderboardEntryModel>> watchGlobalLeaderboard({int limit = 50}) {
    return _firestore.users
        .orderBy('elo', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(LeaderboardEntryModel.fromFirestore).toList());
  }

  Stream<HeadToHeadRecordModel?> watchHeadToHead(String uidA, String uidB) {
    final pairingId = FirestorePaths.pairingId(uidA, uidB);
    return _firestore.leaderboardPairings.doc(pairingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HeadToHeadRecordModel.fromFirestore(doc);
    });
  }
}
