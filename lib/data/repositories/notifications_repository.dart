import '../../core/services/firestore_service.dart';
import '../models/notification_model.dart';

/// A user's in-app inbox. Entries are created only by Cloud Functions (as a
/// side effect of `sendFriendRequest`/`sendDuelChallenge`); this repository
/// only reads them and toggles `read`, the one field `firestore.rules`
/// lets a client write directly on its own notification.
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
}
