import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// The "player vs player" scoreboard strip shown at the top of the live
/// duel screen — this is the moment that has to feel alive, so both sides
/// get a strong identity color (see [AppColors.playerOne]/[playerTwo]).
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        children: [
          Text(
            roundLabel,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: _PlayerBadge(name: player1Name, score: player1Score, color: AppColors.playerOne)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
              ),
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
        ],
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
        Text('$score', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color)),
      ],
    );
  }
}
