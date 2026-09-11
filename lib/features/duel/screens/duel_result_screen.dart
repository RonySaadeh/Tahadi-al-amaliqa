import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/level_calculator.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../home/home_controller.dart';
import '../live_duel_controller.dart';

/// The post-duel screen: the outcome floods the entire screen in its own
/// color rather than being reported by a badge on a neutral page. Win, loss
/// and draw are three visually different places to be standing, which is
/// what makes winning feel like something.
///
/// All of this data already exists on the (now completed) `duels/{duelId}`
/// document and the player's own profile — this screen just presents it.
class DuelResultScreen extends ConsumerStatefulWidget {
  const DuelResultScreen({super.key, required this.duelId});

  final String duelId;

  @override
  ConsumerState<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends ConsumerState<DuelResultScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final duelAsync = ref.watch(duelStreamProvider(widget.duelId));
    final myUid = ref.watch(currentUserIdProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.arenaDark,
      body: duelAsync.when(
        loading: () => const Center(child: BrandedLoadingIndicator(onDark: true)),
        error: (error, _) => Center(
          child: Text(
            l10n.commonError,
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onArenaMuted),
          ),
        ),
        data: (duel) {
          final user = userAsync.value;
          if (duel == null || myUid == null || user == null) {
            return const Center(child: BrandedLoadingIndicator(onDark: true));
          }

          final iWon = duel.winnerId == myUid;
          final isDraw = duel.winnerId == null || duel.winnerId!.isEmpty;
          final myScore = duel.scoreFor(myUid);
          final opponentScore = duel.scoreFor(duel.opponentIdFor(myUid));
          final myEloChange = duel.eloChange[myUid] ?? 0;
          final opponentName = duel.opponentDisplayNameFor(myUid);

          // Reconstructs this duel's "before" wins/losses from the current
          // (post-match) totals — draws touch neither counter (see
          // `updatePlayerAfterDuel` in resolveDuel.ts), so only a win/loss
          // outcome needs undoing here. No extra read needed: the delta is
          // exactly this duel's own result.
          final levelAfter = LevelCalculator.calculate(wins: user.wins, losses: user.losses);
          final levelBefore = LevelCalculator.calculate(
            wins: user.wins - (iWon ? 1 : 0),
            losses: user.losses - (!iWon && !isDraw ? 1 : 0),
          );
          final leveledUp = levelAfter.level > levelBefore.level;

          if (iWon) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
          }

          final flood = isDraw
              ? AppColors.drawGradient
              : (iWon ? AppColors.winGradient : AppColors.lossGradient);
          final accent = isDraw ? AppColors.textDisabled : (iWon ? AppColors.gold : AppColors.error);
          final headline = isDraw ? l10n.duelDraw : (iWon ? l10n.duelYouWin : l10n.duelYouLose);
          final badge = isDraw
              ? l10n.duelResultBadgeDraw
              : (iWon ? l10n.duelResultBadgeWin : l10n.duelResultBadgeLoss);
          final resultIcon = isDraw
              ? Icons.handshake_rounded
              : (iWon ? Icons.emoji_events_rounded : Icons.shield_moon_rounded);

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: flood))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: ResponsiveCenter(
                    child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      _BadgeChip(label: badge, color: accent)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .moveY(begin: -8, end: 0),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        headline.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
                      ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.85, 0.85)),

                      const Spacer(),

                      Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: iWon ? AppColors.goldGradient : null,
                              color: iWon ? null : Colors.white.withValues(alpha: 0.07),
                              border: iWon ? null : Border.all(color: accent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.45),
                                  blurRadius: 44,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              resultIcon,
                              size: 52,
                              color: iWon ? AppColors.onBrand : accent,
                            ),
                          )
                          .animate()
                          .scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                          ),

                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.duelFinalScore.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _ScoreLine(myScore: myScore, opponentScore: opponentScore)
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 300.ms),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.playerProfilePath(duel.opponentIdFor(myUid)),
                        ),
                        child: Text(
                          l10n.duelVs(opponentName),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onArenaMuted,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.onArenaMuted,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      _EloDelta(delta: myEloChange, label: l10n.duelEloChange)
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 300.ms),

                      if (leveledUp) ...[
                        const SizedBox(height: AppSpacing.md),
                        _LevelUpBanner(level: levelAfter.level)
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 300.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      ],

                      const Spacer(),

                      SlabButton(
                        label: l10n.duelPlayAgain,
                        icon: Icons.replay_rounded,
                        background: AppColors.gold,
                        foreground: AppColors.onBrand,
                        onPressed: () => context.go(AppRoutes.duelLobby),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SlabButton(
                        label: l10n.duelBackHome,
                        background: Colors.white.withValues(alpha: 0.12),
                        depthColor: Colors.black.withValues(alpha: 0.35),
                        fontSize: 13,
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    ),
                  ),
                ),
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                numberOfParticles: 24,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.3,
                colors: const [AppColors.gold, AppColors.primary, AppColors.playerOne],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onBrand),
      ),
    );
  }
}

/// The two scores keep their arena identity colors — you are cyan on every
/// screen, they are magenta — so the result reads as the same two forces
/// that were just clashing, not as an abstract pair of numbers.
class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.myScore, required this.opponentScore});

  final int myScore;
  final int opponentScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle = theme.textTheme.displayLarge?.copyWith(fontSize: 46);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      // Pinned LTR: a score pair reorders under RTL bidi rules, and the
      // left-hand number must stay the local player's on both scripts.
      textDirection: TextDirection.ltr,
      children: [
        Text('$myScore', style: numberStyle?.copyWith(color: AppColors.playerOne)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'VS',
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted, fontSize: 13),
          ),
        ),
        Text('$opponentScore', style: numberStyle?.copyWith(color: AppColors.playerTwo)),
      ],
    );
  }
}

class _EloDelta extends StatelessWidget {
  const _EloDelta({required this.delta, required this.label});

  final int delta;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = delta >= 0;
    final color = positive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            // Pinned LTR — a leading '+'/'-' reorders under RTL bidi rules.
            Formatters.signedElo(delta),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.duelLevelUp.toUpperCase(),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 18, color: AppColors.onBrand),
          ),
          Text(
            l10n.duelReachedLevel(level),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrand),
          ),
        ],
      ),
    );
  }
}
