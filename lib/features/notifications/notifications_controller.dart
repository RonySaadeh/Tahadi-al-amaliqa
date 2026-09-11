import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/notification_model.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final myUid = ref.watch(currentUserIdProvider);
  if (myUid == null) return const Stream.empty();
  return ref.watch(notificationsRepositoryProvider).watchNotifications(myUid);
});

/// Count shown on the notification bell's badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0;
});

final notificationsControllerProvider = Provider<NotificationsController>(NotificationsController.new);

class NotificationsController {
  NotificationsController(this._ref);

  final Ref _ref;

  Future<void> markRead(String notificationId) {
    return _ref.read(notificationsRepositoryProvider).markRead(notificationId);
  }
}
