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

  /// Every friendship/request touching [uid], newest first. A single
  /// `array-contains` query against `participantIds` (`== [uidA, uidB]`,
  /// written by `sendFriendRequest`) rather than two separate
  /// `fromUserId`/`toUserId` queries merged client-side: Firestore refuses a
  /// `list` query against a rule that ORs two different `resource.data`
  /// fields when the query only filters one of them (it can't prove every
  /// possible result satisfies the untested field) — see the read rule on
  /// `friendships` in `firestore.rules`.
  Stream<List<FriendshipModel>> watchMyFriendships(String uid) {
    return _firestore.friendships.where('participantIds', arrayContains: uid).snapshots().map((snap) {
      final list = snap.docs.map(FriendshipModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Finds players by exact Player ID or by a case-insensitive name prefix,
  /// merging both into one deduped result list (excluding [myUid]).
  ///
  /// Three queries run in parallel:
  /// - `playerId` exact match, normalized the same way [UserModel] generates
  ///   codes (dashes/spaces stripped, uppercased) — lets one player find
  ///   another by the code on their profile without knowing their name.
  /// - `displayNameLower` prefix match — case-insensitive, but only finds
  ///   accounts created (or renamed) after this field was introduced.
  /// - `displayName` prefix match — the original field, case-sensitive, kept
  ///   as a fallback so older accounts without `displayNameLower` are still
  ///   findable by a correctly-cased name.
  Future<List<UserModel>> searchUsers({required String query, required String myUid}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final normalizedId = trimmed.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final lowerName = trimmed.toLowerCase();

    final snapshots = await Future.wait([
      _firestore.users.where('playerId', isEqualTo: normalizedId).limit(1).get(),
      _firestore.users
          .orderBy('displayNameLower')
          .startAt([lowerName])
          .endAt(['$lowerName\uf8ff'])
          .limit(20)
          .get(),
      _firestore.users.orderBy('displayName').startAt([trimmed]).endAt(['$trimmed\uf8ff']).limit(20).get(),
    ]);

    final byUid = <String, UserModel>{};
    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        final user = UserModel.fromFirestore(doc);
        if (user.uid != myUid) byUid[user.uid] = user;
      }
    }
    return byUid.values.toList();
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
