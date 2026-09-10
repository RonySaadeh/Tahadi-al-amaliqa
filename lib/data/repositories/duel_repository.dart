import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import '../models/duel_invite_model.dart';
import '../models/duel_model.dart';
import '../models/open_lobby_model.dart';
import '../models/round_model.dart';

/// Everything about the live duel flow: reading duel/round state in
/// real time, and forwarding every state-changing action (accept a
/// challenge, submit an answer, ...) to its Cloud Function. See the
/// "server-authoritative" note in `core/services/cloud_functions_service.dart`
/// for why writes never happen directly against Firestore here.
class DuelRepository {
  DuelRepository({FirestoreService? firestoreService, CloudFunctionsService? cloudFunctions})
    : _firestore = firestoreService ?? FirestoreService(),
      _cloudFunctions = cloudFunctions ?? CloudFunctionsService();

  final FirestoreService _firestore;
  final CloudFunctionsService _cloudFunctions;

  Stream<DuelModel?> watchDuel(String duelId) {
    return _firestore.duels.doc(duelId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DuelModel.fromFirestore(doc);
    });
  }

  Stream<List<RoundModel>> watchRounds(String duelId) {
    return _firestore
        .duelRounds(duelId)
        .orderBy('roundNumber')
        .snapshots()
        .map((snap) => snap.docs.map(RoundModel.fromFirestore).toList());
  }

  Stream<RoundModel?> watchRound(String duelId, int roundNumber) {
    return _firestore.duelRounds(duelId).doc(roundNumber.toString()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoundModel.fromFirestore(doc);
    });
  }

  /// Incoming challenges for the current user that are still pending.
  Stream<List<DuelInviteModel>> watchIncomingInvites(String uid) {
    return _firestore.duelInvites
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DuelInviteModel.fromFirestore).toList());
  }

  /// Recent duels involving [uid], most recent first. Used on the home
  /// screen's "recent duels" list and the profile screen's history.
  Stream<List<DuelModel>> watchRecentDuelsFor(String uid, {int limit = 10}) {
    return _firestore.duels
        .where('player1Id', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DuelModel.fromFirestore).toList());
    // NOTE: this only covers duels where the user is player1. Firestore
    // can't OR two different-field equality clauses in one query without a
    // composite index + array trick. The pragmatic fix used by
    // `duel_controller.dart` is to merge this with a second query on
    // `player2Id` client-side. See that controller for the merge logic.
  }

  Stream<List<DuelModel>> watchRecentDuelsAsPlayerTwo(String uid, {int limit = 10}) {
    return _firestore.duels
        .where('player2Id', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(DuelModel.fromFirestore).toList());
  }

  Future<Map<String, dynamic>> joinOpenLobby({String? categoryId}) {
    return _cloudFunctions.joinOpenLobby(categoryId: categoryId);
  }

  Future<void> leaveOpenLobby(String lobbyId) => _cloudFunctions.leaveOpenLobby(lobbyId);

  /// Watches a single quick-match queue entry so the lobby screen can
  /// notice the moment another player's `joinOpenLobby` call matches into
  /// it (i.e. `duelId` goes from null to set) and navigate automatically.
  Stream<OpenLobbyModel?> watchOpenLobby(String lobbyId) {
    return _firestore.openLobbies.doc(lobbyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OpenLobbyModel.fromFirestore(doc);
    });
  }

  Future<void> sendChallenge({required String toUserId, required String categoryId}) {
    return _cloudFunctions.sendDuelChallenge(toUserId: toUserId, categoryId: categoryId);
  }

  Future<Map<String, dynamic>> respondToChallenge({required String inviteId, required bool accept}) {
    return _cloudFunctions.respondToDuelChallenge(inviteId: inviteId, accept: accept);
  }

  Future<void> submitAnswer({required String duelId, required int roundNumber, required int selectedIndex}) {
    return _cloudFunctions.submitAnswer(
      duelId: duelId,
      roundNumber: roundNumber,
      selectedIndex: selectedIndex,
    );
  }

  /// See `DuelPresenceController` — called periodically while the local
  /// player is in an active duel so their opponent can detect a disconnect.
  Future<void> sendHeartbeat(String duelId) => _cloudFunctions.sendDuelHeartbeat(duelId);

  /// Claims a win because the opponent has been unreachable for longer than
  /// the reconnect grace period. The server re-checks this before honoring
  /// it, so calling this speculatively/early is harmless.
  Future<void> forfeitDuel(String duelId) => _cloudFunctions.forfeitDuel(duelId);
}
