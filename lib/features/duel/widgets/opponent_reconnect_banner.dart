import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Non-blocking banner shown at the top of [LiveDuelScreen] while the
/// opponent's heartbeat looks stale — see `DuelPresenceController`. Doesn't
/// stop this player from playing their own turn; there's nothing else
/// useful to do but wait it out.
class OpponentReconnectBanner extends StatelessWidget {
  const OpponentReconnectBanner({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.duelOpponentReconnecting(secondsRemaining),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
