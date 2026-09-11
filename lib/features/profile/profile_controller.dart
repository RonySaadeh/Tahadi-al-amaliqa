import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/user_model.dart';
import '../home/home_controller.dart';

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

  /// Called from `ProfileScreen` the moment it sees the signed-in player's
  /// own doc missing a `playerId` — an account created before that field
  /// existed. `firestore.rules` only allows this exact write while
  /// `playerId` is still absent, so it's safe to call this unconditionally
  /// every time that's true rather than tracking "have I already tried".
  Future<void> backfillLegacyPlayerId(UserModel user) async {
    if (user.playerId.isNotEmpty) return;
    await ref
        .read(userRepositoryProvider)
        .backfillLegacyProfileFields(
          user.uid,
          playerId: UserModel.generatePlayerId(),
          displayName: user.displayName,
        );
  }
}

final profileControllerProvider = NotifierProvider<ProfileController, AsyncValue<void>>(
  ProfileController.new,
);

/// Self-heals an account created before Player ID existed, the moment its
/// own profile doc is seen missing one — same "run a side effect as a
/// plain `Provider<void>` reacts" pattern as `presenceControllerProvider`
/// in `core_providers.dart`. Watched from `ProfileScreen`; harmless to
/// re-run on every `currentUserProvider` emission (e.g. a presence
/// heartbeat) since it's a no-op once `playerId` is no longer empty.
final playerIdBackfillProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user != null && user.playerId.isEmpty) {
    ref.read(profileControllerProvider.notifier).backfillLegacyPlayerId(user);
  }
});
