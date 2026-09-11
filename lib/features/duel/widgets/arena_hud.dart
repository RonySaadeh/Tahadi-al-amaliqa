import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// The scoreboard across the top of the arena: you on one side, your
/// opponent on the other, and whatever the moment calls for between them
/// (the countdown ring while a question is live, the clash mark once it
/// resolves).
///
/// Sides are **you vs. them**, not player1 vs. player2. Each device colors
/// its own player cyan and the other magenta, so "my color" is a fixed fact
/// a player can rely on at a glance mid-duel instead of something they have
/// to re-derive from names every round.
class ArenaHud extends StatelessWidget {
  const ArenaHud({
    super.key,
    required this.myName,
    required this.myScore,
    required this.opponentName,
    required this.opponentScore,
    required this.center,
  });

  final String myName;
  final int myScore;
  final String opponentName;
  final int opponentScore;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _Side(
            name: myName,
            score: myScore,
            color: AppColors.playerOne,
            alignEnd: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: center,
        ),
        Expanded(
          child: _Side(
            name: opponentName,
            score: opponentScore,
            color: AppColors.playerTwo,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

/// The clash mark that occupies the HUD's center slot between rounds, so the
/// slot never collapses and the two scores never drift toward each other.
class ClashMark extends StatelessWidget {
  const ClashMark({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.arenaDeep,
        border: Border.all(color: AppColors.arenaRaised, width: 3),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => AppColors.vsGradient.createShader(bounds),
        child: Text(
          'VS',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: size * 0.3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.score,
    required this.color,
    required this.alignEnd,
  });

  final String name;
  final int score;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    final avatar = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    );

    final readout = Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
          child: Text(
            '$score',
            key: ValueKey(score),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 24, color: color),
          ),
        ),
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted, fontSize: 9),
        ),
      ],
    );

    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[avatar, const SizedBox(width: AppSpacing.sm)],
        Flexible(child: readout),
        if (alignEnd) ...[const SizedBox(width: AppSpacing.sm), avatar],
      ],
    );
  }
}
