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
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../home/home_controller.dart';
import '../live_duel_controller.dart';

/// The post-duel screen: win/lose/draw banner, final score, ELO change,
/// confetti for a win, and a level-up moment when this duel's outcome
/// pushed the player's [LevelCalculator] level past its threshold. All of
/// this data already exists on the (now completed) `duels/{duelId}`
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
    final duelAsync = ref.watch(duelStreamProvider(widget.duelId));
    final myUid = ref.watch(currentUserIdProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: duelAsync.when(
          loading: () => const Center(child: BrandedLoadingIndicator()),
          error: (error, _) => Center(child: Text(l10n.commonError)),
          data: (duel) {
            final user = userAsync.value;
            if (duel == null || myUid == null || user == null) {
              return const Center(child: BrandedLoadingIndicator());
            }

            final iWon = duel.winnerId == myUid;
            final isDraw = duel.winnerId == null || duel.winnerId!.isEmpty;
            final myScore = duel.scoreFor(myUid);
            final opponentScore = duel.scoreFor(duel.opponentIdFor(myUid));
            final myEloChange = duel.eloChange[myUid] ?? 0;
            final opponentName = duel.opponentDisplayNameFor(myUid);

            // Reconstructs this duel's "before" wins/losses from the
            // current (post-match) totals — draws touch neither counter
            // (see `updatePlayerAfterDuel` in resolveDuel.ts), so only a
            // win/loss outcome needs undoing here. No extra read needed:
            // the delta is exactly this duel's own result.
            final levelAfter = LevelCalculator.calculate(wins: user.wins, losses: user.losses);
            final levelBefore = LevelCalculator.calculate(
              wins: user.wins - (iWon ? 1 : 0),
              losses: user.losses - (!iWon && !isDraw ? 1 : 0),
            );
            final leveledUp = levelAfter.level > levelBefore.level;

            if (iWon) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
            }

            final resultLabel = isDraw ? l10n.duelDraw : (iWon ? l10n.duelYouWin : l10n.duelYouLose);
            final resultColor = isDraw
                ? AppColors.textSecondary
                : (iWon ? AppColors.success : AppColors.error);
            final resultIcon = isDraw
                ? Icons.handshake_rounded
                : (iWon ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded);

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 1.2,
                      colors: [resultColor.withValues(alpha: 0.16), AppColors.background],
                    ),
                  ),
                  child: SizedBox.expand(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: resultColor.withValues(alpha: 0.15),
                                  border: Border.all(color: resultColor, width: 2),
                                ),
                                child: Icon(resultIcon, color: resultColor, size: 44),
                              )
                              .animate()
                              .scale(
                                duration: 400.ms,
                                curve: Curves.elasticOut,
                                begin: const Offset(0.3, 0.3),
                              ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            resultLabel,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: resultColor),
                          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.duelVs(opponentName),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                          const SizedBox(height: AppSpacing.xl),
                          Text(l10n.duelFinalScore, style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          // Forced LTR — see the comment on ScorePopup: a
                          // score pair reorders under RTL bidi rules unless
                          // pinned.
                          Text(
                            '$myScore  —  $opponentScore',
                            textDirection: TextDirection.ltr,
                            style: Theme.of(context).textTheme.displayMedium,
                          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                          const SizedBox(height: AppSpacing.lg),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.trending_up_rounded, color: AppColors.gold),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(l10n.duelEloChange, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Forced LTR — see the comment on
                                  // ScorePopup: a leading '+'/'-' reorders
                                  // under RTL bidi rules unless pinned.
                                  Text(
                                    Formatters.signedElo(myEloChange),
                                    textDirection: TextDirection.ltr,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: myEloChange >= 0 ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                          if (leveledUp) ...[
                            const SizedBox(height: AppSpacing.md),
                            _LevelUpBanner(level: levelAfter.level)
                                .animate()
                                .fadeIn(delay: 450.ms, duration: 300.ms)
                                .scale(begin: const Offset(0.9, 0.9)),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          ElevatedButton(
                            onPressed: () => context.go(AppRoutes.duelLobby),
                            child: Text(l10n.duelPlayAgain),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.home),
                            child: Text(l10n.duelBackHome),
                          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.duelLevelUp,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.onBrand, fontWeight: FontWeight.w900),
          ),
          Text(
            l10n.duelReachedLevel(level),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBrand),
          ),
        ],
      ),
    );
  }
}
