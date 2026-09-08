import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/leaderboard_entry_model.dart';

/// Both the global ranking and head-to-head lookups are cheap reads (see
/// `data/repositories/leaderboard_repository.dart` for why) so this
/// controller is just a thin pass-through — no client-side aggregation.

final globalLeaderboardProvider = StreamProvider<List<LeaderboardEntryModel>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchGlobalLeaderboard();
});

typedef PlayerPair = ({String uidA, String uidB});

final headToHeadProvider = StreamProvider.family<HeadToHeadRecordModel?, PlayerPair>((ref, pair) {
  return ref.watch(leaderboardRepositoryProvider).watchHeadToHead(pair.uidA, pair.uidB);
});
