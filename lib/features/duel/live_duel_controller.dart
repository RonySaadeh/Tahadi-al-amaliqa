import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/duel_model.dart';
import '../../data/models/round_model.dart';

/// Live-duel gameplay state, scoped per `duelId`.
///
/// This deliberately holds very little: which round is showing, and
/// (locally, optimistically) which option the current player tapped. The
/// question content, correctness, and points are never decided here — they
/// come straight from Firestore listeners on `duels/{duelId}` and
/// `duels/{duelId}/rounds/{n}`, which only change when a Cloud Function
/// writes them. See `functions/src/scoring/resolveDuel.ts`.

final duelStreamProvider = StreamProvider.family<DuelModel?, String>((ref, duelId) {
  return ref.watch(duelRepositoryProvider).watchDuel(duelId);
});

typedef RoundKey = ({String duelId, int roundNumber});

final roundStreamProvider = StreamProvider.family<RoundModel?, RoundKey>((ref, key) {
  return ref.watch(duelRepositoryProvider).watchRound(key.duelId, key.roundNumber);
});

/// Tracks the option index the local player tapped for a given round, purely
/// for instant UI feedback (disabling the other options) while we wait for
/// the server to confirm via [roundStreamProvider]. Resets automatically
/// whenever the round key changes because it's a `family` provider — a new
/// round gets a fresh instance.
class SelectedAnswerController extends Notifier<int?> {
  SelectedAnswerController(this.arg);

  /// Riverpod 3 dropped the old `FamilyNotifier` base class — a family
  /// notifier is now just a plain [Notifier] whose provider passes the
  /// family argument straight to its constructor (see
  /// `selectedAnswerProvider` below), so we store it ourselves instead of
  /// getting an `arg` property for free.
  final RoundKey arg;

  @override
  int? build() => null;

  Future<void> select(int index) async {
    if (state != null) return; // already answered this round
    state = index;
    try {
      await ref
          .read(duelRepositoryProvider)
          .submitAnswer(duelId: arg.duelId, roundNumber: arg.roundNumber, selectedIndex: index);
    } catch (_) {
      // Let them try again — the round is still active until the server
      // says otherwise.
      state = null;
    }
  }
}

final selectedAnswerProvider = NotifierProvider.family<SelectedAnswerController, int?, RoundKey>(
  SelectedAnswerController.new,
);

/// Whether the opponent in a duel appears to have lost their connection,
/// and — if so — how many seconds remain before this player can claim an
/// automatic forfeit win.
///
/// Null [opponentSecondsRemaining] means the opponent's last heartbeat is
/// recent enough not to worry about.
class DuelPresenceState {
  const DuelPresenceState({this.opponentSecondsRemaining});

  final int? opponentSecondsRemaining;
}

/// Drives opponent-disconnect detection for an active duel from the
/// perspective of a *still-connected* player.
///
/// Two independent things happen here:
/// - Every [AppConstants.duelHeartbeatIntervalSeconds], this player's own
///   presence is refreshed via `heartbeat`, so the opponent's copy of this
///   same controller can see we're still here.
/// - Every second, the opponent's last known heartbeat (as reflected in
///   [duelStreamProvider]) is checked against
///   [AppConstants.duelReconnectGraceSeconds]. Once it's been stale that
///   long, `forfeitDuel` is called — the server independently re-verifies
///   the staleness before honoring it, so calling this a little eagerly (or
///   more than once) is harmless.
///
/// The disconnected player's own "you're offline, reconnect within 35s" UI
/// is separate — see `LiveDuelScreen`'s use of `connectivityStatusProvider`
/// — this controller only ever meaningfully fires on the side of whoever
/// still has a connection.
class DuelPresenceController extends Notifier<DuelPresenceState> {
  DuelPresenceController(this.duelId);

  final String duelId;

  /// How stale the opponent's heartbeat must be before this even counts as
  /// a possible disconnect — a couple of missed/delayed pings shouldn't
  /// trigger anything.
  static const _warningThresholdSeconds = AppConstants.duelHeartbeatIntervalSeconds * 2;

  Timer? _heartbeatTimer;
  Timer? _watchTimer;
  bool _forfeitInFlight = false;

  @override
  DuelPresenceState build() {
    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      _watchTimer?.cancel();
    });

    final repo = ref.read(duelRepositoryProvider);
    repo.sendHeartbeat(duelId);
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.duelHeartbeatIntervalSeconds),
      (_) => repo.sendHeartbeat(duelId),
    );
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    return const DuelPresenceState();
  }

  void _tick() {
    final duel = ref.read(duelStreamProvider(duelId)).value;
    final myUid = ref.read(currentUserIdProvider);
    if (duel == null || myUid == null || duel.isFinished) {
      state = const DuelPresenceState();
      return;
    }

    final reference = duel.opponentLastSeenAtFor(myUid) ?? duel.startedAt ?? duel.createdAt;
    final staleSeconds = DateTime.now().difference(reference).inSeconds;

    if (staleSeconds < _warningThresholdSeconds) {
      state = const DuelPresenceState();
      return;
    }

    final remaining = AppConstants.duelReconnectGraceSeconds - staleSeconds;
    if (remaining > 0) {
      state = DuelPresenceState(opponentSecondsRemaining: remaining);
      return;
    }

    state = const DuelPresenceState(opponentSecondsRemaining: 0);
    if (!_forfeitInFlight) {
      _forfeitInFlight = true;
      ref
          .read(duelRepositoryProvider)
          .forfeitDuel(duelId)
          .catchError((_) {
            // Opponent may have reconnected right at the edge and the
            // server rejected it — fine, the next tick reassesses from
            // fresh state.
          })
          .whenComplete(() => _forfeitInFlight = false);
    }
  }
}

final duelPresenceProvider = NotifierProvider.family<DuelPresenceController, DuelPresenceState, String>(
  DuelPresenceController.new,
);
