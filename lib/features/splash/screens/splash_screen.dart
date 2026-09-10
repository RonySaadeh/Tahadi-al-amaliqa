import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
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
    final authAsync = ref.watch(authStateChangesProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline = authAsync.hasValue && authAsync.value == null && connectivityAsync.value == false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: BrandedLoadingIndicator(message: l10n.splashChecking)),
            // A real pop-up (an `AlertDialog` laid out inline rather than
            // pushed via `showDialog`) over a dimming scrim — declarative,
            // so it appears/disappears purely from `isOffline` flipping
            // rather than needing imperative Navigator bookkeeping to avoid
            // stacking duplicate dialogs or dismissing a stale one.
            if (isOffline) ...[
              Positioned.fill(child: ColoredBox(color: AppColors.background.withValues(alpha: 0.85))),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _NoConnectionDialog(l10n: l10n, ref: ref),
              ),
            ],
          ],
        ),
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
    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      icon: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
      title: Text(l10n.splashNoConnectionTitle, textAlign: TextAlign.center),
      content: Text(l10n.splashNoConnectionMessage, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.icon(
          onPressed: () => ref.invalidate(connectivityStatusProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.commonRetry),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
