import 'package:cloud_functions/cloud_functions.dart';

/// Wraps every callable Cloud Function the app invokes.
///
/// Design rule for this whole app: **the client never writes duel results,
/// scores, ELO, or question answer keys directly to Firestore.** Every
/// state-changing action a player takes goes through one of these callables
/// so a Cloud Function (running with admin privileges, and only trusting
/// its own server clock) can validate and apply it. Firestore security
/// rules back this up by making those documents client-write-blocked — see
/// `firestore.rules`.
///
/// Matches the functions defined under `functions/src/`.
class CloudFunctionsService {
  CloudFunctionsService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> joinOpenLobby({String? categoryId}) async {
    final result = await _functions.httpsCallable('joinOpenLobby').call({
      if (categoryId != null) 'categoryId': categoryId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> leaveOpenLobby(String lobbyId) async {
    await _functions.httpsCallable('leaveOpenLobby').call({'lobbyId': lobbyId});
  }

  Future<void> sendDuelChallenge({required String toUserId, required String categoryId}) async {
    await _functions.httpsCallable('sendDuelChallenge').call({
      'toUserId': toUserId,
      'categoryId': categoryId,
    });
  }

  Future<Map<String, dynamic>> respondToDuelChallenge({
    required String inviteId,
    required bool accept,
  }) async {
    final result = await _functions.httpsCallable('respondToDuelChallenge').call({
      'inviteId': inviteId,
      'accept': accept,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// The ONLY way a player's answer gets recorded. The server timestamps
  /// the receipt itself — the client's local time is never trusted for
  /// speed scoring.
  Future<void> submitAnswer({
    required String duelId,
    required int roundNumber,
    required int selectedIndex,
  }) async {
    await _functions.httpsCallable('submitAnswer').call({
      'duelId': duelId,
      'roundNumber': roundNumber,
      'selectedIndex': selectedIndex,
    });
  }

  /// Refreshes this player's presence timestamp on the duel doc, used by
  /// their opponent's client to detect a disconnect — see
  /// `DuelPresenceController` and `functions/src/scoring/presence.ts`.
  Future<void> sendDuelHeartbeat(String duelId) async {
    await _functions.httpsCallable('heartbeat').call({'duelId': duelId});
  }

  /// Claims an automatic win because the opponent's last heartbeat is older
  /// than [AppConstants.duelReconnectGraceSeconds] — the server re-verifies
  /// this independently before honoring it.
  Future<void> forfeitDuel(String duelId) async {
    await _functions.httpsCallable('forfeitDuel').call({'duelId': duelId});
  }

  Future<String> createHomeTurfCategory({required String name, required String description}) async {
    final result = await _functions.httpsCallable('createHomeTurfCategory').call({
      'name': name,
      'description': description,
    });
    return (result.data as Map)['categoryId'] as String;
  }

  Future<void> addHomeTurfQuestion({
    required String categoryId,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    required String difficulty,
  }) async {
    await _functions.httpsCallable('addHomeTurfQuestion').call({
      'categoryId': categoryId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty,
    });
  }
}
