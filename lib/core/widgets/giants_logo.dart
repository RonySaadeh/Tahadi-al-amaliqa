import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's identity mark: a gold **G** on a violet slab, tilted a few
/// degrees off square.
///
/// The tilt is the whole idea — a perfectly upright badge reads as a default
/// app icon, and three degrees of rotation is enough to read as *placed*.
/// Reused at every scale from the splash hero down to a form header, so the
/// mark is the same object everywhere rather than a different drawing per
/// screen.
class GiantsMonogram extends StatelessWidget {
  const GiantsMonogram({super.key, this.size = 112, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(size * 0.26),
          border: Border.all(color: AppColors.gold, width: size * 0.02),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    blurRadius: size * 0.45,
                    spreadRadius: size * 0.02,
                  ),
                ]
              : null,
        ),
        child: Text(
          'G',
          // The mark is a Latin monogram in both locales — a logo is an
          // image of a name, not a translation of one.
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: size * 0.52,
            color: AppColors.gold,
            shadows: [
              Shadow(
                offset: Offset(0, size * 0.035),
                color: AppColors.onBrand.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The stacked wordmark — a quiet first line over a loud second one, with
/// the hard offset shadow that ties the type to the slab geometry used by
/// every button in the app.
class GiantsWordmark extends StatelessWidget {
  const GiantsWordmark({super.key, this.scale = 1, this.alignment = CrossAxisAlignment.center});

  final double scale;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          l10n.brandLineOne.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 17 * scale,
            color: AppColors.playerOne,
            letterSpacing: 2.5,
          ),
        ),
        Text(
          l10n.brandLineTwo.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 40 * scale,
            color: AppColors.gold,
            letterSpacing: 1.5,
            height: 1,
            shadows: [
              Shadow(offset: Offset(0, 4 * scale), color: AppColors.primaryDim),
            ],
          ),
        ),
      ],
    );
  }
}

/// Monogram over wordmark — the full lockup, for the splash and auth heroes.
class GiantsLockup extends StatelessWidget {
  const GiantsLockup({super.key, this.monogramSize = 112, this.wordmarkScale = 1});

  final double monogramSize;
  final double wordmarkScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GiantsMonogram(size: monogramSize),
        SizedBox(height: AppSpacing.lg * wordmarkScale),
        GiantsWordmark(scale: wordmarkScale),
      ],
    );
  }
}
