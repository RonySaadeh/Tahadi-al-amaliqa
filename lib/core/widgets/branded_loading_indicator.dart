import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's replacement for a bare `CircularProgressIndicator`: a pulsing
/// gold trophy glyph with an optional message underneath. Used for
/// matchmaking, question generation, and any other spinner moment so it
/// still feels like this app instead of a generic form.
///
/// Set [onDark] when placing it on an arena field — the message color has to
/// flip, and a dark-on-dark caption is the single easiest way to lose a
/// loading state entirely.
class BrandedLoadingIndicator extends StatelessWidget {
  const BrandedLoadingIndicator({super.key, this.message, this.onDark = false});

  final String? message;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.onBrand, size: 36),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.05, 1.05),
              duration: 700.ms,
              curve: Curves.easeInOut,
            ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onDark ? AppColors.onArenaMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
