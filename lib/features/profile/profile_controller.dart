import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';

/// The profile screen reuses `currentUserProvider` from the home feature
/// (see `features/home/home_controller.dart`) and `myCategoriesProvider`
/// from home_turf (see `features/home_turf/home_turf_controller.dart`) for
/// the data it displays — there's exactly one stream of "my profile" and
/// one of "my categories" in the whole app, and both features read from
/// them rather than each maintaining a copy.
///
/// The only thing unique to this feature is editing your display name.
class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateDisplayName(String displayName) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).updateProfile(uid, displayName: displayName);
    });
  }

  /// Sets the player's preferred language (`'ar'` or `'en'`) — drives both
  /// the app's own UI locale (see `main.dart`) and, from their next duel
  /// onward, which language its questions are picked in (`createDuel`
  /// reads this same field).
  Future<void> updateLocale(String locale) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).updateProfile(uid, locale: locale);
    });
  }
}

final profileControllerProvider = NotifierProvider<ProfileController, AsyncValue<void>>(
  ProfileController.new,
);
