import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';

/// The two connection-loss pop-ups shown over `LiveDuelScreen`, one for each
/// side of a drop. Which one appears — if either — is decided entirely by
/// `DuelPresenceController`, where the two are mutually exclusive by
/// construction, so both players can never be told that the *other* one
/// dropped.
///
/// Both are laid out inline over a [ModalBarrier] rather than pushed with
/// `showDialog`: they appear and disappear purely from presence state
/// flipping, with no imperative Navigator bookkeeping to stack duplicates or
/// strand a stale dialog once the connection comes back.

/// Shown to the player whose *own* connection dropped — they're on the clock
/// to get back before their opponent is awarded the win.
class SelfDisconnectDialog extends ConsumerWidget {
  const SelfDisconnectDialog({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timeUp = secondsRemaining <= 0;

    return _DisconnectDialog(
      icon: Icons.wifi_off_rounded,
      accent: timeUp ? AppColors.error : AppColors.warning,
      title: timeUp ? l10n.duelReconnectTimeUpTitle : l10n.duelReconnectingTitle,
      message: timeUp ? l10n.duelReconnectTimeUpMessage : l10n.duelReconnectingMessage,
      countdownSeconds: timeUp ? null : secondsRemaining,
      action: timeUp
          ? null
          : SlabButton(
              label: l10n.commonRetry,
              icon: Icons.refresh_rounded,
              background: AppColors.primary,
              onPressed: () => ref.invalidate(connectivityStatusProvider),
            ),
    );
  }
}

/// Shown to the player who is *still connected* while their opponent has
/// gone quiet. There is nothing to do but wait them out, so this one has no
/// action button — just the countdown to the automatic win.
class OpponentDisconnectDialog extends StatelessWidget {
  const OpponentDisconnectDialog({super.key, required this.secondsRemaining, required this.opponentName});

  final int secondsRemaining;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeUp = secondsRemaining <= 0;

    return _DisconnectDialog(
      icon: Icons.person_off_rounded,
      accent: AppColors.warning,
      title: timeUp ? l10n.duelOpponentTimeUpTitle : l10n.duelOpponentDisconnectedTitle,
      message: timeUp ? l10n.duelOpponentTimeUpMessage : l10n.duelOpponentDisconnectedMessage(opponentName),
      countdownSeconds: timeUp ? null : secondsRemaining,
      footnote: timeUp ? null : l10n.duelOpponentForfeitCountdown,
      // Time's up means `forfeitDuel` is in flight — the duel doc flipping to
      // completed is what actually moves this player on, so hold a spinner
      // rather than a button that would do nothing.
      action: timeUp ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)) : null,
    );
  }
}

class _DisconnectDialog extends StatelessWidget {
  const _DisconnectDialog({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    this.countdownSeconds,
    this.footnote,
    this.action,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final int? countdownSeconds;
  final String? footnote;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    // Deliberately an arena-dark panel rather than a light Material dialog:
    // this only ever appears over the duel, and a white sheet dropping onto
    // the arena would break the one screen the whole identity rests on.
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child:
                Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.arenaDark,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
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
                              color: accent.withValues(alpha: 0.16),
                            ),
                            child: Icon(icon, size: 32, color: accent),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                          ),
                          if (countdownSeconds != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '$countdownSeconds${l10n.commonSeconds}',
                              textDirection: TextDirection.ltr,
                              style: textTheme.displayMedium?.copyWith(color: accent),
                            ),
                          ],
                          if (footnote != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              footnote!.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
                            ),
                          ],
                          if (action != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            action!,
                          ],
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
          ),
        ),
      ],
    );
  }
}
