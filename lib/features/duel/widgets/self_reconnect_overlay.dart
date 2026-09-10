import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen blocker shown over [LiveDuelScreen] the instant this
/// player's own device loses its connection mid-duel — "the 35 second
/// reconnecting phase". Counts down locally from
/// [AppConstants.duelReconnectGraceSeconds]; purely cosmetic on this side,
/// since with no connection this client can't do anything server-side
/// anyway — it's the opponent's client (`DuelPresenceController`) that
/// actually claims the forfeit once the real grace period elapses.
///
/// Dismissed automatically the moment [connectivityStatusProvider] reports
/// true again; [LiveDuelScreen]'s own duel listener then reflects whatever
/// really happened (still active, or already lost by forfeit).
class SelfReconnectOverlay extends ConsumerStatefulWidget {
  const SelfReconnectOverlay({super.key});

  @override
  ConsumerState<SelfReconnectOverlay> createState() => _SelfReconnectOverlayState();
}

class _SelfReconnectOverlayState extends ConsumerState<SelfReconnectOverlay> {
  int _secondsRemaining = AppConstants.duelReconnectGraceSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _secondsRemaining == 0) return;
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeUp = _secondsRemaining == 0;

    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.97),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: timeUp ? AppColors.error : AppColors.warning),
              const SizedBox(height: AppSpacing.lg),
              Text(
                timeUp ? l10n.duelReconnectTimeUpTitle : l10n.duelReconnectingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                timeUp ? l10n.duelReconnectTimeUpMessage : l10n.duelReconnectingMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!timeUp) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$_secondsRemaining${l10n.commonSeconds}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.warning),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(connectivityStatusProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
