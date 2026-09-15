import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// The "Double Score" announcement shown over `LiveDuelScreen` at the start
/// of the duel's last round, before that round's question appears.
///
/// Laid out the same way as `_DisconnectDialog` — an arena-dark panel over a
/// non-dismissible barrier — since it appears and disappears purely from
/// `_LiveDuelScreenState`'s local timer flipping, with no imperative
/// Navigator bookkeeping. That timer is sized to match how long the server
/// delays the bonus round's `startedAt` (see `AppConstants.doubleScorePopupSeconds`
/// and `resolveDuel.ts`'s `DOUBLE_SCORE_POPUP_SECONDS`), so the round's
/// answer window starts right as this popup disappears rather than ticking
/// down underneath it.
class DoubleScorePopup extends StatelessWidget {
  const DoubleScorePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

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
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 48,
                            spreadRadius: 4,
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
                              color: AppColors.gold.withValues(alpha: 0.16),
                            ),
                            child: const Icon(Icons.bolt_rounded, size: 32, color: AppColors.gold),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.duelDoubleScoreTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 26,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                            begin: 1,
                            end: 1.06,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.duelDoubleScoreMessage,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ),
        ),
      ],
    );
  }
}
