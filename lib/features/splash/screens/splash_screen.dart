import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/mascot_assets.dart';
import '../../../core/widgets/giants_logo.dart';
import '../../../core/widgets/mascot_display.dart';
import '../../../l10n/app_localizations.dart';

/// The very first screen on every cold start (`initialLocation` in
/// `app_router.dart`). Its only job is to sit here until the app knows two
/// things: whether there's a signed-in session, and whether the device
/// actually has internet access. The router's `redirect` reads the same
/// providers this screen watches and moves on automatically once both are
/// resolved *and* the device is online — this screen never navigates itself.
///
/// The device being offline holds every cold start here, signed in or not:
/// this screen keeps showing its loading state, just swapping the caption to
/// the offline message, and picks back up the instant connectivity returns
/// (`connectivityStatusProvider` re-checks live, no user action required).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline = connectivityAsync.hasValue && connectivityAsync.value == false;

    return Scaffold(
      backgroundColor: AppColors.arenaDark,
      // `StackFit.expand` is load-bearing, not decoration. Scaffold hands
      // its body *loose* constraints, and a Stack sizes itself to its
      // largest non-positioned child — here the Column, whose width is just
      // its longest line of text. Without this the whole screen collapses
      // to text width, every `Positioned.fill` below fills that narrow box
      // instead of the display, and the rest of the screen is bare
      // `backgroundColor`. See test/splash_screen_test.dart.
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.arenaGradient)),
          ),
          // A single soft violet bloom behind the mark, so the dark field
          // has a light source instead of reading as flat paint.
          //
          // It has to be a *radial gradient* that lands on fully transparent
          // at its edge, not a flat-colored circle: a flat circle keeps a
          // hard rim, and since the bloom is deliberately larger than the
          // screen, that rim gets clipped by the screen edge and reads as a
          // giant half-disc of violet sitting on the splash rather than as
          // light. Fading to transparent means there's no edge to clip.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.55),
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.26),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                const MascotDisplay(mood: MascotMood.idle, size: 200)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
                const SizedBox(height: AppSpacing.lg),
                const GiantsWordmark()
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.arenaRaised,
                          valueColor: AlwaysStoppedAnimation(
                            isOffline ? AppColors.error : AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        (isOffline ? l10n.splashOffline : l10n.splashChecking).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOffline ? AppColors.error : AppColors.onArenaMuted,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
