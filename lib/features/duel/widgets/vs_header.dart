import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// The "player vs player" scoreboard strip shown at the top of the live
/// duel screen — this is the moment that has to feel alive, so both sides
/// get a strong identity color (see [AppColors.playerOne]/[playerTwo]) and
/// the score itself animates on every change instead of just snapping to
/// the new number.
class VsHeader extends StatelessWidget {
  const VsHeader({
    super.key,
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    required this.roundLabel,
  });

  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final String roundLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusLg)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(roundLabel, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _PlayerBadge(name: player1Name, score: player1Score, color: AppColors.playerOne)),
              const _VsBadge(),
              Expanded(
                child: _PlayerBadge(
                  name: player2Name,
                  score: player2Score,
                  color: AppColors.playerTwo,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.vsGradient)),
        ],
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
        child: const Text(
          'VS',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({required this.name, required this.score, required this.color, this.alignEnd = false});

  final String name;
  final int score;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
          child: Text(
            '$score',
            key: ValueKey(score),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
