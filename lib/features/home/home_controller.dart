import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/user_model.dart';

/// The home screen only needs the signed-in player's own profile — everything
/// else it shows (recent duels) is reused from `features/duel/duel_controller.dart`
/// so there's a single source for that stream instead of two.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});
