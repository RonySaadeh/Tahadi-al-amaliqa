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
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../live_duel_controller.dart';

/// The post-duel screen: win/lose/draw banner, final score, ELO change, and
/// confetti for a win. All of this data already exists on the (now
/// completed) `duels/{duelId}` document — this screen just presents it.
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: duelAsync.when(
          loading: () => const Center(child: BrandedLoadingIndicator()),
          error: (error, _) => Center(child: Text(l10n.commonError)),
          data: (duel) {
            if (duel == null || myUid == null) return Center(child: Text(l10n.commonError));

            final iWon = duel.winnerId == myUid;
            final isDraw = duel.winnerId == null || duel.winnerId!.isEmpty;
            final myScore = duel.scoreFor(myUid);
            final opponentScore = duel.scoreFor(duel.opponentIdFor(myUid));
            final myEloChange = duel.eloChange[myUid] ?? 0;

            if (iWon) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
            }

            final resultLabel = isDraw ? l10n.duelDraw : (iWon ? l10n.duelYouWin : l10n.duelYouLose);
            final resultColor = isDraw
                ? AppColors.textSecondary
                : (iWon ? AppColors.success : AppColors.error);

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        resultLabel,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(color: resultColor),
                      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: AppSpacing.xl),
                      Text(l10n.duelFinalScore, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: AppSpacing.xs),
                      // Forced LTR — see the comment on ScorePopup: a score
                      // pair reorders under RTL bidi rules unless pinned.
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
                              // Forced LTR — see the comment on ScorePopup:
                              // a leading '+'/'-' reorders under RTL bidi
                              // rules unless pinned.
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
