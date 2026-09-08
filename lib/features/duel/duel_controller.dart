import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/category_group_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/duel_invite_model.dart';
import '../../data/models/duel_model.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/models/open_lobby_model.dart';

/// State/logic for challenging friends, quick-matching, and responding to
/// incoming challenges. The actual live-duel gameplay (answering questions,
/// round timing) lives in `live_duel_controller.dart` — this controller
/// only covers the lobby: picking an opponent/category and getting a
/// `duelId` to navigate to.
class DuelController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> sendChallenge({required String toUserId, required String categoryId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(duelRepositoryProvider).sendChallenge(toUserId: toUserId, categoryId: categoryId);
    });
  }

  /// Returns the new duel's id if the invite was accepted, otherwise null.
  Future<String?> respondToChallenge({required String inviteId, required bool accept}) async {
    state = const AsyncValue.loading();
    String? duelId;
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(duelRepositoryProvider)
          .respondToChallenge(inviteId: inviteId, accept: accept);
      duelId = result['duelId'] as String?;
    });
    return duelId;
  }

  /// Joins the quick-match queue. If someone was already waiting, this
  /// returns a `duelId` immediately. Otherwise it returns a `lobbyId` and
  /// also records it in [queuedLobbyIdProvider], so `duel_lobby_screen.dart`
  /// can show a "searching" state and — via [openLobbyStreamProvider] —
  /// notice the moment a *later* caller's `joinOpenLobby` matches into this
  /// same entry and stamps a `duelId` onto it.
  Future<Map<String, dynamic>> joinQuickMatch({String? categoryId}) async {
    state = const AsyncValue.loading();
    Map<String, dynamic> result = {};
    state = await AsyncValue.guard(() async {
      result = await ref.read(duelRepositoryProvider).joinOpenLobby(categoryId: categoryId);
      final lobbyId = result['lobbyId'] as String?;
      if (lobbyId != null) {
        ref.read(queuedLobbyIdProvider.notifier).set(lobbyId);
      }
    });
    return result;
  }

  /// Clears the queued state and, if we're still actually queued (as
  /// opposed to having just been matched), tells the server to remove the
  /// lobby entry.
  Future<void> cancelQuickMatch() async {
    final lobbyId = ref.read(queuedLobbyIdProvider);
    if (lobbyId == null) return;
    ref.read(queuedLobbyIdProvider.notifier).set(null);
    await ref.read(duelRepositoryProvider).leaveOpenLobby(lobbyId);
  }

  /// Called once [openLobbyStreamProvider] reports a `duelId` — stops
  /// treating us as queued now that the duel itself is what matters.
  void clearQueueAfterMatch() {
    ref.read(queuedLobbyIdProvider.notifier).set(null);
  }
}

final duelControllerProvider = NotifierProvider<DuelController, AsyncValue<void>>(
  DuelController.new,
);

/// The lobby entry id we're currently waiting in, or null. Held as its own
/// provider (rather than local widget state) so it survives switching away
/// from the Duel tab and back while a quick match is still pending.
class QueuedLobbyIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? lobbyId) => state = lobbyId;
}

final queuedLobbyIdProvider = NotifierProvider<QueuedLobbyIdController, String?>(
  QueuedLobbyIdController.new,
);

final openLobbyStreamProvider = StreamProvider.family<OpenLobbyModel?, String>((ref, lobbyId) {
  return ref.watch(duelRepositoryProvider).watchOpenLobby(lobbyId);
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(questionRepositoryProvider).watchAllCategories();
});

final categoryGroupsProvider = StreamProvider<List<CategoryGroupModel>>((ref) {
  return ref.watch(questionRepositoryProvider).watchCategoryGroups();
});

/// Reuses the global leaderboard as the "pick an opponent" list — in a small
/// friend group everyone on the leaderboard is a valid opponent, so there's
/// no separate friends list to maintain.
final opponentCandidatesProvider = StreamProvider<List<LeaderboardEntryModel>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  return ref
      .watch(leaderboardRepositoryProvider)
      .watchGlobalLeaderboard()
      .map((entries) => entries.where((e) => e.uid != myUid).toList());
});

final incomingInvitesProvider = StreamProvider<List<DuelInviteModel>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  if (myUid == null) return const Stream.empty();
  return ref.watch(duelRepositoryProvider).watchIncomingInvites(myUid);
});

/// Merges the two "am I player1 or player2" queries into one sorted,
/// deduplicated recent-duels list. Firestore can't OR two different-field
/// equality filters in one query, so we run both and combine client-side —
/// cheap at this app's per-user duel volume.
final recentDuelsProvider = StreamProvider<List<DuelModel>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  if (myUid == null) return const Stream.empty();

  final repo = ref.watch(duelRepositoryProvider);
  return _mergeByCreatedAt(
    repo.watchRecentDuelsFor(myUid),
    repo.watchRecentDuelsAsPlayerTwo(myUid),
  );
});

Stream<List<DuelModel>> _mergeByCreatedAt(
  Stream<List<DuelModel>> a,
  Stream<List<DuelModel>> b, {
  int limit = 10,
}) {
  late final StreamController<List<DuelModel>> controller;
  List<DuelModel> latestA = const [];
  List<DuelModel> latestB = const [];
  StreamSubscription<List<DuelModel>>? subA;
  StreamSubscription<List<DuelModel>>? subB;

  void emitMerged() {
    final merged = {for (final d in [...latestA, ...latestB]) d.id: d}.values.toList()
      ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    controller.add(merged.take(limit).toList());
  }

  controller = StreamController<List<DuelModel>>.broadcast(
    onListen: () {
      subA = a.listen((value) {
        latestA = value;
        emitMerged();
      });
      subB = b.listen((value) {
        latestB = value;
        emitMerged();
      });
    },
    onCancel: () {
      subA?.cancel();
      subB?.cancel();
    },
  );

  return controller.stream;
}
