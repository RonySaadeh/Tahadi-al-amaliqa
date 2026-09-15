import '../../core/services/firestore_service.dart';
import '../models/notification_model.dart';

/// A user's in-app inbox. Entries are created only by Cloud Functions (as a
/// side effect of `sendFriendRequest`/`sendDuelChallenge`); this repository
/// only reads them, toggles `read`, and deletes — the two things
/// `firestore.rules` lets a client do directly on its own notification.
class NotificationsRepository {
  NotificationsRepository({FirestoreService? firestoreService})
    : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  Stream<List<NotificationModel>> watchNotifications(String uid, {int limit = 50}) {
    return _firestore.notifications
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markRead(String notificationId) {
    return _firestore.notifications.doc(notificationId).update({'read': true});
  }

  /// Dismisses one notification from the inbox permanently. Safe even for a
  /// still-pending friend request/duel challenge — both stay actionable from
  /// their own screen (the Friends tab's incoming requests, the home
  /// screen's invite card), not just here.
  Future<void> deleteNotification(String notificationId) {
    return _firestore.notifications.doc(notificationId).delete();
  }
}
