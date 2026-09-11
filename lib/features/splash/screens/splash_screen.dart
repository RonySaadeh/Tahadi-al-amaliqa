import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/giants_logo.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';

/// The very first screen on every cold start (`initialLocation` in
/// `app_router.dart`). Its only job is to sit here until the app knows two
/// things: whether there's a signed-in session, and — only if there isn't
/// one — whether the device actually has internet access. The router's
/// `redirect` reads the same two providers this screen watches and moves on
/// automatically the instant both are resolved; this screen never navigates
/// itself.
///
/// A signed-in user never lingers here waiting on a connectivity check —
/// see the redirect logic's comment for why that's a deliberate choice:
/// showing a *new* signed-out user a login form with nothing to submit to
/// is the actual problem being solved, not an already-authenticated
/// session that's merely offline for a moment (Firestore's own offline
/// cache handles that gracefully once inside the app).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authAsync = ref.watch(authStateChangesProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline =
        authAsync.hasValue && authAsync.value == null && connectivityAsync.value == false;

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
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.arenaRaised,
                          valueColor: AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.splashChecking.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                ),
              ],
            ),
          ),

          // A real pop-up laid out inline rather than pushed via
          // `showDialog` — declarative, so it appears/disappears purely from
          // `isOffline` flipping rather than needing imperative Navigator
          // bookkeeping to avoid stacking duplicates or stranding a stale one.
          if (isOffline) ...[
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Color(0xB3000000)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _NoConnectionDialog(l10n: l10n, ref: ref),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoConnectionDialog extends StatelessWidget {
  const _NoConnectionDialog({required this.l10n, required this.ref});

  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.arenaDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.error, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.splashNoConnectionTitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.splashNoConnectionMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              SlabButton(
                label: l10n.commonRetry,
                icon: Icons.refresh_rounded,
                background: AppColors.primary,
                onPressed: () => ref.invalidate(connectivityStatusProvider),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}
