import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// One doc per unordered pair of users, stored at `friendships/{pairingId}`
/// with `pairingId` the same deterministic sorted-uid id
/// `FirestorePaths.pairingId` produces for `leaderboardPairings` — so a
/// duplicate friend request or duplicate friendship between the same two
/// people is structurally impossible, not just checked for. `status` moves
/// pending -> accepted/declined; written only by
/// `sendFriendRequest`/`respondToFriendRequest`.
class FriendshipModel extends Equatable {
  const FriendshipModel({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  String otherUserId(String myUid) => myUid == fromUserId ? toUserId : fromUserId;

  /// A pending request someone else sent *to* [myUid] — the one that shows
  /// up with Accept/Decline.
  bool isIncomingFor(String myUid) => status == FriendshipStatus.pending && toUserId == myUid;

  /// A pending request [myUid] sent that's still awaiting a reply.
  bool isOutgoingFor(String myUid) => status == FriendshipStatus.pending && fromUserId == myUid;

  factory FriendshipModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FriendshipModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromDisplayName: data['fromDisplayName'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      status: FriendshipStatus.fromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, fromUserId, fromDisplayName, toUserId, status, createdAt, respondedAt];
}
