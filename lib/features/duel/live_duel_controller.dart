import 'package:flutter_riverpod/flutter_riverpod.dart';

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
