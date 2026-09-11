import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// One entry in a player's in-app inbox, stored at `notifications/{id}`.
/// Created only by Cloud Functions as a side effect of the real action
/// (`sendFriendRequest`, `sendDuelChallenge`) — never written directly.
/// `read` is the one field the client may flip itself; see
/// `firestore.rules`.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.relatedId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String fromUserId;
  final String fromDisplayName;

  /// The `friendships` doc id (for [NotificationType.friendRequest]) or the
  /// `duelInvites` doc id (for [NotificationType.duelChallenge]) this
  /// notification is about — so its Accept/Decline buttons can act on the
  /// real thing directly, through the same functions the rest of the app
  /// already uses for that.
  final String relatedId;
  final bool read;
  final DateTime createdAt;

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String? ?? 'friend_request'),
      fromUserId: data['fromUserId'] as String? ?? '',
      fromDisplayName: data['fromDisplayName'] as String? ?? '',
      relatedId: data['relatedId'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, type, fromUserId, fromDisplayName, relatedId, read, createdAt];
}
