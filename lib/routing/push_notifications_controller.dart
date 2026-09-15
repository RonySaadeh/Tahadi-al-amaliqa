import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/core_providers.dart';
import 'app_router.dart';

/// Maps a push's `data` payload (`{'type': ..., 'relatedId': ...}`, set
/// server-side in `functions/src/lib/push.ts`) to where tapping it should
/// take the player. Null means "just open the app" — fine for a type with
/// nowhere more specific to go, like `announcement`.
String? notificationRoutePathFor(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final relatedId = data['relatedId'] as String?;

  if (type == 'duel_challenge_accepted' && relatedId != null && relatedId.isNotEmpty) {
    return AppRoutes.duelIntroPath(relatedId);
  }
  if (type == 'friend_request' || type == 'friend_request_accepted' || type == 'duel_challenge') {
    return AppRoutes.notifications;
  }
  return null;
}

/// Registers this device for push notifications and keeps its FCM token
/// fresh in Firestore for as long as a session is signed in, subscribes it
/// to the global-announcements topic, and navigates when a push is tapped —
/// see `PushNotificationService` for the raw FCM plumbing this drives.
///
/// Watched from the very top of the widget tree (see `TahadiApp` in
/// `main.dart`), not `AppShell` — unlike `presenceControllerProvider`, which
/// is deliberately scoped to just the main shell, this needs to keep running
/// even while a full-screen route like the live duel screen is showing, so
/// a token refresh or a backgrounded-then-tapped notification is never
/// missed just because the player is mid-duel.
final pushNotificationsControllerProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return;

  final service = ref.watch(pushNotificationServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final router = ref.watch(goRouterProvider);

  void handleTap(RemoteMessage message) {
    final path = notificationRoutePathFor(message.data);
    if (path != null) router.go(path);
  }

  Future<void> register() async {
    final token = await service.requestPermissionAndGetToken();
    if (token == null) return;
    await userRepository.registerFcmToken(uid, token);
    await service.subscribeToGlobalTopic();
  }

  register();

  final tokenRefreshSub = service.onTokenRefresh.listen(
    (token) => userRepository.registerFcmToken(uid, token),
  );
  final openedAppSub = service.onMessageOpenedApp.listen(handleTap);

  service.getInitialMessage().then((message) {
    if (message != null) handleTap(message);
  });

  // Removing this device's token on sign-out happens in
  // `AuthController.signOut` instead of here: by the time this provider
  // notices `uid` went to null and disposes, Firebase Auth has already
  // cleared its local session, so a write attempted from here would just
  // fail `firestore.rules`' `request.auth.uid == uid` check.
  ref.onDispose(() {
    tokenRefreshSub.cancel();
    openedAppSub.cancel();
  });
});
