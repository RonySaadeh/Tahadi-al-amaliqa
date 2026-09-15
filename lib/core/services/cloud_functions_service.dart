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

  Future<Map<String, dynamic>> sendDuelChallenge({
    required String toUserId,
    required String categoryId,
  }) async {
    final result = await _functions.httpsCallable('sendDuelChallenge').call({
      'toUserId': toUserId,
      'categoryId': categoryId,
    });
    return Map<String, dynamic>.from(result.data as Map);
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

  Future<void> sendFriendRequest({required String toUserId}) async {
    await _functions.httpsCallable('sendFriendRequest').call({'toUserId': toUserId});
  }

  Future<void> respondToFriendRequest({required String otherUserId, required bool accept}) async {
    await _functions.httpsCallable('respondToFriendRequest').call({
      'otherUserId': otherUserId,
      'accept': accept,
    });
  }

  Future<void> removeFriend({required String otherUserId}) async {
    await _functions.httpsCallable('removeFriend').call({'otherUserId': otherUserId});
  }

  // --- App Control (admin-only; each callable re-checks `isAdmin` server
  // side — see `functions/src/admin/appControl.ts`) ---

  Future<void> setMaintenanceMode({required bool enabled, required String message}) async {
    await _functions.httpsCallable('setMaintenanceMode').call({
      'enabled': enabled,
      'message': message,
    });
  }

  Future<void> setForceUpdate({
    required bool enabled,
    required String minVersion,
    required String message,
    required String updateUrl,
  }) async {
    await _functions.httpsCallable('setForceUpdate').call({
      'enabled': enabled,
      'minVersion': minVersion,
      'message': message,
      'url': updateUrl,
    });
  }

  Future<void> setLimitedEvent({
    required bool active,
    required String title,
    required String description,
    DateTime? endsAt,
  }) async {
    await _functions.httpsCallable('setLimitedEvent').call({
      'active': active,
      'title': title,
      'description': description,
      'endsAt': endsAt?.toIso8601String(),
    });
  }

  /// Fans a one-off announcement out to every player's notification inbox
  /// (see `NotificationType.announcement`) — not a persisted toggle the way
  /// the other three are, so there's nothing to "turn off" afterward.
  Future<void> sendGlobalNotification({required String title, required String message}) async {
    await _functions.httpsCallable('sendGlobalNotification').call({
      'title': title,
      'message': message,
    });
  }

  /// One-off cleanup for friend-request/duel-challenge notifications a past
  /// bug left behind after they were already accepted or declined — see
  /// `cleanupResolvedNotifications` in `functions/src/admin/appControl.ts`.
  /// Returns how many notifications were scanned and how many were deleted.
  Future<Map<String, dynamic>> cleanupResolvedNotifications() async {
    final result = await _functions.httpsCallable('cleanupResolvedNotifications').call();
    return Map<String, dynamic>.from(result.data as Map);
  }
}
