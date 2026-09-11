import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/giants_logo.dart';
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.arenaGradient)),
          ),
          // A single soft violet bloom behind the mark, so the dark field
          // has a light source instead of reading as flat paint.
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                const GiantsLockup()
                    .animate()
                    .fadeIn(duration: 500.ms)
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
