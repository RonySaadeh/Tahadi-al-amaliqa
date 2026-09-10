import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../live_duel_controller.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/duel_timer.dart';
import '../widgets/opponent_reconnect_banner.dart';
import '../widgets/score_popup.dart';
import '../widgets/self_reconnect_overlay.dart';
import '../widgets/vs_header.dart';

/// The moment the whole app is built around: both players see the same
/// question at the same time, race to answer, and see the result the
/// instant the server resolves it. No screen in the app should feel more
/// alive than this one.
///
/// This widget is intentionally "dumb": every value it shows (question,
/// correctness, points, whose turn) comes straight from
/// `duelStreamProvider`/`roundStreamProvider`, which mirror
/// `duels/{duelId}` and `duels/{duelId}/rounds/{n}` in real time. There is
/// no local game-state machine to keep in sync with the server — advancing
/// to the next round happens automatically because `duel.currentRound`
/// changing is itself what this screen watches.
class LiveDuelScreen extends ConsumerWidget {
  const LiveDuelScreen({super.key, required this.duelId});

  final String duelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final duelAsync = ref.watch(duelStreamProvider(duelId));
    final myUid = ref.watch(currentUserIdProvider);

    // Keeps `DuelPresenceController` alive for the lifetime of this screen —
    // it sends this player's heartbeat and watches the opponent's for a
    // stale-connection forfeit. See that controller for the full picture.
    final presence = ref.watch(duelPresenceProvider(duelId));

    // This player's own connection, not the opponent's — see
    // `SelfReconnectOverlay`.
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isSelfOffline = connectivityAsync.hasValue && connectivityAsync.value == false;

    ref.listen(duelStreamProvider(duelId), (previous, next) {
      final duel = next.value;
      if (duel != null && duel.status == DuelStatus.completed) {
        context.go(AppRoutes.duelResultPath(duelId));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: duelAsync.when(
              loading: () => const Center(child: BrandedLoadingIndicator()),
              error: (error, _) => Center(child: Text(l10n.commonError)),
              data: (duel) {
                if (duel == null || myUid == null) {
                  return Center(child: Text(l10n.commonError));
                }

                final roundKey = (duelId: duelId, roundNumber: duel.currentRound);
                final roundAsync = ref.watch(roundStreamProvider(roundKey));

                return roundAsync.when(
                  loading: () => Center(child: BrandedLoadingIndicator(message: l10n.commonLoading)),
                  error: (error, _) => Center(child: Text(l10n.commonError)),
                  data: (round) {
                    if (round == null) return Center(child: BrandedLoadingIndicator(message: l10n.commonLoading));

                    final selectedIndex = ref.watch(selectedAnswerProvider(roundKey));
                    final hasAnswered = selectedIndex != null;
                    final isResolved = round.isResolved;
                    final myPoints = round.pointsAwarded[myUid] ?? 0;
                    final myAnswerIndex = round.playerAnswers[myUid];

                    return Column(
                      children: [
                        VsHeader(
                          player1Name: duel.player1DisplayName,
                          player2Name: duel.player2DisplayName,
                          player1Score: duel.player1Score,
                          player2Score: duel.player2Score,
                          roundLabel: l10n.duelRoundOf(duel.currentRound, duel.totalRounds),
                        ),
                        if (presence.opponentSecondsRemaining != null)
                          OpponentReconnectBanner(secondsRemaining: presence.opponentSecondsRemaining!),
                        const SizedBox(height: AppSpacing.md),
                        if (!isResolved)
                          DuelTimer(
                            roundStartedAt: round.startedAt,
                            onTimeUp: () {
                              if (!hasAnswered) {
                                ref.read(selectedAnswerProvider(roundKey).notifier).select(-1);
                              }
                            },
                          ),
                        if (isResolved) ScorePopup(pointsEarned: myPoints, wasCorrect: myAnswerIndex == round.correctAnswerIndex),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            round.questionText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: round.options.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final state = _visualStateFor(
                                index: index,
                                isResolved: isResolved,
                                correctIndex: round.correctAnswerIndex,
                                myAnswerIndex: isResolved ? myAnswerIndex : selectedIndex,
                              );
                              return AnswerOptionTile(
                                label: round.options[index],
                                visualState: state,
                                onTap: (hasAnswered || isResolved)
                                    ? null
                                    : () => ref.read(selectedAnswerProvider(roundKey).notifier).select(index),
                              );
                            },
                          ),
                        ),
                        if (hasAnswered && !isResolved)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(l10n.duelWaitingOpponentAnswer, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        if (duel.isHomeTurfDuel)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              l10n.duelHomeTurfBonus,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gold),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (isSelfOffline) const SelfReconnectOverlay(),
        ],
      ),
    );
  }

  AnswerTileVisualState _visualStateFor({
    required int index,
    required bool isResolved,
    required int? correctIndex,
    required int? myAnswerIndex,
  }) {
    if (!isResolved) {
      return index == myAnswerIndex ? AnswerTileVisualState.selected : AnswerTileVisualState.neutral;
    }
    if (index == correctIndex) return AnswerTileVisualState.correct;
    if (index == myAnswerIndex) return AnswerTileVisualState.incorrect;
    return AnswerTileVisualState.missed;
  }
}
