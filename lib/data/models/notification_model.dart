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
    this.title,
    this.message,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String fromUserId;
  final String fromDisplayName;

  /// The `friendships` doc id ([NotificationType.friendRequest]/
  /// [NotificationType.friendRequestAccepted]), the `duelInvites` doc id
  /// ([NotificationType.duelChallenge]), or the `duels` doc id
  /// ([NotificationType.duelChallengeAccepted] — the duel this challenge
  /// became) this notification is about. For [NotificationType.friendRequest]/
  /// [NotificationType.duelChallenge] it's what the Accept/Decline buttons
  /// act on directly; for the two `*Accepted` types there's nothing to
  /// accept, but tapping a [NotificationType.duelChallengeAccepted] tile
  /// still uses it to jump straight into the duel. Empty for
  /// [NotificationType.announcement], which isn't about any other document.
  final String relatedId;
  final bool read;
  final DateTime createdAt;

  /// Only set for [NotificationType.announcement] — the free-text title and
  /// body an admin wrote in the App Control panel and sent via
  /// `sendGlobalNotification`. Null for every other type, whose display text
  /// is built from [fromDisplayName] instead (see `NotificationTile`).
  final String? title;
  final String? message;

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
      title: data['title'] as String?,
      message: data['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    fromUserId,
    fromDisplayName,
    relatedId,
    read,
    createdAt,
    title,
    message,
  ];
}
