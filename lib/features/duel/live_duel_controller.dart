import 'dart:async';

import 'package:equatable/equatable.dart';
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

/// Who — if anyone — has lost their connection in an active duel, from the
/// local player's point of view.
///
/// The two fields are mutually exclusive by construction, and that is the
/// whole point: a client whose own connection is down cannot know anything
/// about its opponent, because the opponent's heartbeat stops arriving for
/// exactly the same reason either way. Letting both sides accuse each other
/// is what made a healthy duel show "opponent disconnected" on *both*
/// devices at once. [selfSecondsRemaining] always wins.
class DuelPresenceState extends Equatable {
  const DuelPresenceState({this.selfSecondsRemaining, this.opponentSecondsRemaining});

  /// Seconds until *this* player forfeits, set only when this device is the
  /// one that lost its connection. Null while this player is healthy.
  final int? selfSecondsRemaining;

  /// Seconds until the *opponent* forfeits, set only when they've gone quiet
  /// while this player is still connected. Null otherwise.
  final int? opponentSecondsRemaining;

  bool get isSelfDisconnected => selfSecondsRemaining != null;
  bool get isOpponentDisconnected => opponentSecondsRemaining != null;

  @override
  List<Object?> get props => [selfSecondsRemaining, opponentSecondsRemaining];
}

/// Drives connection-loss detection for an active duel, deciding each second
/// which side (if either) has dropped.
///
/// Two independent things happen here:
/// - Every [AppConstants.duelHeartbeatIntervalSeconds], this player's own
///   presence is refreshed via `heartbeat`. Whether that call *lands* is how
///   this device knows its own connection is alive — see [_sendHeartbeat].
/// - Every second, [_tick] decides whose connection is in trouble and, if
///   the opponent has been gone past [AppConstants.duelReconnectGraceSeconds],
///   claims the win via `forfeitDuel`. The server independently re-verifies
///   staleness before honoring it, so calling this a little eagerly (or more
///   than once) is harmless.
///
/// Both staleness measurements compare two readings of *this device's own*
/// clock, never a local clock against a server-stamped timestamp. Phone
/// clocks are routinely minutes off, and a skewed one would otherwise make
/// a perfectly healthy opponent look permanently disconnected.
class DuelPresenceController extends Notifier<DuelPresenceState> {
  DuelPresenceController(this.duelId);

  final String duelId;

  /// How long a heartbeat must go unrefreshed before it counts as a possible
  /// disconnect — a single missed/delayed ping shouldn't trigger anything.
  static const _warningThresholdSeconds = AppConstants.duelHeartbeatIntervalSeconds * 2;

  Timer? _heartbeatTimer;
  Timer? _watchTimer;
  bool _forfeitInFlight = false;

  /// The opponent heartbeat value last seen, and the local-clock moment it
  /// was seen to change. Staleness is "how long since this device observed
  /// it move", not "how far behind the server's clock it looks".
  DateTime? _lastOpponentBeat;
  late DateTime _opponentBeatSeenAt;

  /// Local-clock moment one of our own heartbeats last actually reached the
  /// server. This — not what the OS reports about the wifi radio — is what
  /// says whether this device is really in the duel: a radio can be
  /// perfectly "connected" to a router that reaches nothing, and it's the
  /// server-side heartbeat the opponent's forfeit claim gets judged against.
  late DateTime _selfBeatAckedAt;

  @override
  DuelPresenceState build() {
    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      _watchTimer?.cancel();
    });

    final now = DateTime.now();
    _opponentBeatSeenAt = now;
    _selfBeatAckedAt = now;

    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.duelHeartbeatIntervalSeconds),
      (_) => _sendHeartbeat(),
    );
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    return const DuelPresenceState();
  }

  Future<void> _sendHeartbeat() async {
    try {
      await ref.read(duelRepositoryProvider).sendHeartbeat(duelId);
      _selfBeatAckedAt = DateTime.now();
    } catch (_) {
      // Deliberately leaves _selfBeatAckedAt where it was: the gap since the
      // last one that landed is exactly this player's own countdown.
    }
  }

  void _tick() {
    final duel = ref.read(duelStreamProvider(duelId)).value;
    final myUid = ref.read(currentUserIdProvider);
    if (duel == null || myUid == null || duel.isFinished) {
      state = const DuelPresenceState();
      return;
    }

    final now = DateTime.now();

    // --- This player's own connection, checked first and exclusively ---
    // The OS reporting "offline" is a faster signal than waiting for
    // heartbeats to time out, but the countdown itself is always anchored on
    // the last heartbeat that actually landed, because that's the timestamp
    // the opponent's forfeit will be judged against server-side.
    final radioOffline = ref.read(connectivityStatusProvider).value == false;
    final selfStaleSeconds = now.difference(_selfBeatAckedAt).inSeconds;
    if (radioOffline || selfStaleSeconds >= _warningThresholdSeconds) {
      final remaining = AppConstants.duelReconnectGraceSeconds - selfStaleSeconds;
      state = DuelPresenceState(selfSecondsRemaining: remaining > 0 ? remaining : 0);
      return;
    }

    // --- The opponent's, only now that we know we can see the world ---
    final opponentBeat = duel.opponentLastSeenAtFor(myUid);
    if (opponentBeat != _lastOpponentBeat) {
      _lastOpponentBeat = opponentBeat;
      _opponentBeatSeenAt = now;
    }

    final opponentStaleSeconds = now.difference(_opponentBeatSeenAt).inSeconds;
    if (opponentStaleSeconds < _warningThresholdSeconds) {
      state = const DuelPresenceState();
      return;
    }

    final remaining = AppConstants.duelReconnectGraceSeconds - opponentStaleSeconds;
    state = DuelPresenceState(opponentSecondsRemaining: remaining > 0 ? remaining : 0);

    if (remaining <= 0 && !_forfeitInFlight) {
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
