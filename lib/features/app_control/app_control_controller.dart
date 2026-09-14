import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../home/home_controller.dart';

export '../../core/providers/core_providers.dart' show appControlProvider;

/// Whether the signed-in player can open the App Control panel — derived
/// from their own profile rather than a separate provider, so it updates
/// live the instant `isAdmin` changes on their `users/{uid}` doc (e.g. right
/// after being granted it in the Firebase console).
final isAppAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).value?.isAdmin ?? false;
});

final appControlControllerProvider = Provider<AppControlController>(AppControlController.new);

/// Thin pass-through to [AppControlRepository]'s admin-only writes. Kept
/// deliberately dumb — no loading/error state of its own — because
/// `AppControlScreen` already needs a per-section "saving" flag for its own
/// UI anyway; see how `NotificationTile._respond` catches its own errors for
/// the same reasoning applied elsewhere in this app.
class AppControlController {
  AppControlController(this._ref);

  final Ref _ref;

  Future<void> setMaintenanceMode({required bool enabled, required String message}) {
    return _ref.read(appControlRepositoryProvider).setMaintenanceMode(enabled: enabled, message: message);
  }

  Future<void> setForceUpdate({
    required bool enabled,
    required String minVersion,
    required String message,
    required String updateUrl,
  }) {
    return _ref.read(appControlRepositoryProvider).setForceUpdate(
      enabled: enabled,
      minVersion: minVersion,
      message: message,
      updateUrl: updateUrl,
    );
  }

  Future<void> setLimitedEvent({
    required bool active,
    required String title,
    required String description,
    DateTime? endsAt,
  }) {
    return _ref.read(appControlRepositoryProvider).setLimitedEvent(
      active: active,
      title: title,
      description: description,
      endsAt: endsAt,
    );
  }

  Future<void> sendGlobalNotification({required String title, required String message}) {
    return _ref.read(appControlRepositoryProvider).sendGlobalNotification(title: title, message: message);
  }
}
