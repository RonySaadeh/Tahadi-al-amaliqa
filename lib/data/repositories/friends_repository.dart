import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

/// Friend requests/friendships, presence, and user search. Follows the same
/// server-authoritative rule as `DuelRepository`: every state-changing
/// action (send/respond to a request) goes through a Cloud Function; this
/// repository only reads Firestore directly and forwards writes.
class FriendsRepository {
  FriendsRepository({FirestoreService? firestoreService, CloudFunctionsService? cloudFunctions})
    : _firestore = firestoreService ?? FirestoreService(),
      _cloudFunctions = cloudFunctions ?? CloudFunctionsService();

  final FirestoreService _firestore;
  final CloudFunctionsService _cloudFunctions;

  /// Every friendship/request [uid] originally sent. Merge with
  /// [watchFriendshipsReceivedBy] (see `friends_controller.dart`) for the
  /// complete picture — Firestore can't OR two different-field equality
  /// clauses in one query, same reasoning as `DuelRepository`'s recent-duels
  /// split.
  Stream<List<FriendshipModel>> watchFriendshipsSentBy(String uid) {
    return _firestore.friendships
        .where('fromUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(FriendshipModel.fromFirestore).toList());
  }

  Stream<List<FriendshipModel>> watchFriendshipsReceivedBy(String uid) {
    return _firestore.friendships
        .where('toUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(FriendshipModel.fromFirestore).toList());
  }

  /// Prefix search on `displayName` — the only "browse users" query
  /// Firestore's native indexing supports without a full-text search
  /// service (there's none set up in this app). Case-sensitive: matches
  /// only names that start with [query] exactly as typed. Excludes [myUid]
  /// so you never find yourself in your own search.
  Future<List<UserModel>> searchUsers({required String query, required String myUid}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final snap = await _firestore.users
        .orderBy('displayName')
        .startAt([trimmed])
        .endAt(['$trimmed'])
        .limit(20)
        .get();

    return snap.docs.map(UserModel.fromFirestore).where((u) => u.uid != myUid).toList();
  }

  Future<void> sendFriendRequest({required String toUserId}) {
    return _cloudFunctions.sendFriendRequest(toUserId: toUserId);
  }

  Future<void> respondToFriendRequest({required String otherUserId, required bool accept}) {
    return _cloudFunctions.respondToFriendRequest(otherUserId: otherUserId, accept: accept);
  }

  /// Stamps this device's "last active" time on the signed-in user's own
  /// profile. A direct Firestore write, not a Cloud Function — see the
  /// narrow presence-only path carved out in `firestore.rules`'s
  /// `users/{uid}` update rule, which requires the timestamp to be the
  /// server's own clock so a client can't fake being online.
  Future<void> updatePresence(String uid) {
    return _firestore.users.doc(uid).update({'lastActiveAt': FieldValue.serverTimestamp()});
  }
}
