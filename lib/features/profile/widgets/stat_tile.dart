import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// One stat in the profile's grid.
///
/// [emphasis] is what keeps that grid from being six identical boxes: the
/// stats a player actually cares about are rendered bigger and left-aligned,
/// the supporting ones stay small and centered. A grid where every cell has
/// the same weight tells you nothing about which number matters.
enum StatEmphasis { hero, normal }

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accentColor = AppColors.gold,
    this.emphasis = StatEmphasis.normal,
    this.icon,
  });

  final String label;
  final String value;
  final Color accentColor;
  final StatEmphasis emphasis;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHero = emphasis == StatEmphasis.hero;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        // A tinted wash of the stat's own color instead of a white card on a
        // near-white page — the tile is identified by its hue, not by an
        // outline around it.
        color: accentColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: isHero ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isHero ? 20 : 16, color: accentColor),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: isHero ? 34 : 20,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: isHero ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
