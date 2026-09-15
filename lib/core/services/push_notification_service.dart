import 'package:firebase_messaging/firebase_messaging.dart';

/// Thin wrapper around [FirebaseMessaging] — permission/token/topic
/// plumbing only. What to do with a token once obtained (write it to
/// Firestore) and what to do when a notification is tapped (navigate) are
/// the caller's job — see `pushNotificationsControllerProvider` in
/// `routing/push_notifications_controller.dart` — the same separation
/// `FirebaseAuthService`/`FirestoreService` keep from their own controllers.
///
/// Deliberately has no foreground-message handling: while the app is
/// already open, the same event that triggers a push has already written a
/// `NotificationDoc` its live Firestore stream picks up (see
/// `NotificationsScreen`), so there's nothing a heads-up banner would add.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Every signed-in device subscribes here so an admin's global
  /// announcement can broadcast in one call — see
  /// `GLOBAL_ANNOUNCEMENTS_TOPIC` in `functions/src/lib/push.ts`. The string
  /// must match exactly on both sides.
  static const String globalAnnouncementsTopic = 'global_announcements';

  /// Requests notification permission — a system prompt on iOS and Android
  /// 13+, a silent no-op grant on older Android — and returns this device's
  /// current FCM token, or null if permission was denied or no token could
  /// be obtained yet (e.g. no network on a cold start).
  Future<String?> requestPermissionAndGetToken() async {
    final settings = await _messaging.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return null;
    return _messaging.getToken();
  }

  /// The device's current token without prompting for permission again —
  /// used on sign-out to know which token to remove, since a denied/never-
  /// granted device still has none to remove.
  Future<String?> currentToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> subscribeToGlobalTopic() => _messaging.subscribeToTopic(globalAnnouncementsTopic);

  /// Fires when a notification is tapped while the app was backgrounded
  /// (not terminated).
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  /// The notification that cold-started the app (tapped while fully
  /// terminated), or null for any other kind of start.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}
