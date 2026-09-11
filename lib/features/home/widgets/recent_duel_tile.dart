import 'package:flutter/material.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/duel_model.dart';

class RecentDuelTile extends StatelessWidget {
  const RecentDuelTile({super.key, required this.duel, required this.myUid, this.onTap});

  final DuelModel duel;
  final String myUid;

  /// Opens the opponent's profile (see `player_profile_screen.dart`), which
  /// is also where this pair's head-to-head record lives — so tapping a
  /// past duel is how "I played them, did I win our record?" gets answered.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final myScore = duel.scoreFor(myUid);
    final opponentScore = duel.scoreFor(duel.opponentIdFor(myUid));
    final opponentName = myUid == duel.player1Id ? duel.player2DisplayName : duel.player1DisplayName;
    final isFinished = duel.status == DuelStatus.completed;
    final iWon = duel.winnerId == myUid;

    final resultColor = !isFinished
        ? AppColors.textSecondary
        : (duel.winnerId == null || duel.winnerId!.isEmpty)
        ? AppColors.textSecondary
        : (iWon ? AppColors.success : AppColors.error);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: CircleAvatar(backgroundColor: resultColor.withValues(alpha: 0.2), child: Icon(Icons.bolt_rounded, color: resultColor)),
      title: Text(opponentName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(duel.categoryName, style: Theme.of(context).textTheme.bodyMedium),
      // Forced LTR — see the comment on ScorePopup: a "12 - 8" style score
      // pair reorders under RTL bidi rules unless pinned.
      trailing: Text(
        '$myScore - $opponentScore',
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: resultColor),
      ),
    );
  }
}
