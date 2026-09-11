import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/friendship_model.dart';
import '../../data/models/user_model.dart';

/// Every friendship/request doc touching the signed-in player, merged from
/// the two possible directions (Firestore can't OR two different-field
/// equality clauses in one query — same reasoning as
/// `duel_controller.dart`'s recent-duels merge) and kept live. Everything
/// else below just filters this one stream, so the friends list, incoming
/// requests, and "have I already asked this person" all agree with each
/// other by construction.
final myFriendshipsProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  if (myUid == null) return const Stream.empty();

  final repo = ref.watch(friendsRepositoryProvider);
  return _mergeFriendships(repo.watchFriendshipsSentBy(myUid), repo.watchFriendshipsReceivedBy(myUid));
});

/// Accepted friendships only, newest-accepted first.
final friendsListProvider = Provider<AsyncValue<List<FriendshipModel>>>((ref) {
  return ref
      .watch(myFriendshipsProvider)
      .whenData((list) => list.where((f) => f.status == FriendshipStatus.accepted).toList());
});

/// Pending requests *sent to* the signed-in player — the ones that show up
/// with Accept/Decline.
final incomingFriendRequestsProvider = Provider<AsyncValue<List<FriendshipModel>>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  return ref.watch(myFriendshipsProvider).whenData((list) {
    if (myUid == null) return const <FriendshipModel>[];
    return list.where((f) => f.isIncomingFor(myUid)).toList();
  });
});

/// How the signed-in player currently relates to [otherUid] — drives which
/// button a search result or another player's profile shows.
enum FriendRelation { none, requestSent, requestReceived, friends }

FriendRelation friendRelationWith(List<FriendshipModel> myFriendships, String myUid, String otherUid) {
  for (final f in myFriendships) {
    if (f.otherUserId(myUid) != otherUid) continue;
    return switch (f.status) {
      FriendshipStatus.accepted => FriendRelation.friends,
      FriendshipStatus.pending => f.fromUserId == myUid
          ? FriendRelation.requestSent
          : FriendRelation.requestReceived,
      FriendshipStatus.declined => FriendRelation.none, // a decline can be re-requested
    };
  }
  return FriendRelation.none;
}

/// Search-by-name results. Held as its own state (rather than a plain
/// `FutureProvider.family` keyed by the query) so the UI can distinguish
/// "haven't searched yet" from "searched, found nothing".
class FriendSearchController extends Notifier<AsyncValue<List<UserModel>>> {
  @override
  AsyncValue<List<UserModel>> build() => const AsyncValue.data([]);

  Future<void> search(String query) async {
    final myUid = ref.read(currentUserIdProvider);
    if (myUid == null || query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(friendsRepositoryProvider).searchUsers(query: query, myUid: myUid),
    );
  }

  void clear() => state = const AsyncValue.data([]);
}

final friendSearchControllerProvider =
    NotifierProvider<FriendSearchController, AsyncValue<List<UserModel>>>(FriendSearchController.new);

/// Sending/accepting/declining a friend request.
class FriendsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> sendRequest(String toUserId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(friendsRepositoryProvider).sendFriendRequest(toUserId: toUserId),
    );
  }

  Future<void> respondToRequest({required String otherUserId, required bool accept}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(friendsRepositoryProvider).respondToFriendRequest(otherUserId: otherUserId, accept: accept),
    );
  }
}

final friendsControllerProvider = NotifierProvider<FriendsController, AsyncValue<void>>(
  FriendsController.new,
);

Stream<List<FriendshipModel>> _mergeFriendships(
  Stream<List<FriendshipModel>> a,
  Stream<List<FriendshipModel>> b,
) {
  late final StreamController<List<FriendshipModel>> controller;
  List<FriendshipModel> latestA = const [];
  List<FriendshipModel> latestB = const [];
  StreamSubscription<List<FriendshipModel>>? subA;
  StreamSubscription<List<FriendshipModel>>? subB;

  void emitMerged() {
    final merged = {for (final f in [...latestA, ...latestB]) f.id: f}.values.toList()
      ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    controller.add(merged);
  }

  controller = StreamController<List<FriendshipModel>>.broadcast(
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
