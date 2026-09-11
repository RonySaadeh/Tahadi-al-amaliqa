import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../live_duel_controller.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/arena_hud.dart';
import '../widgets/duel_disconnect_dialog.dart';
import '../widgets/duel_timer.dart';
import '../widgets/score_popup.dart';

/// The moment the whole app is built around: both players see the same
/// question at the same time, race to answer, and see the result the
/// instant the server resolves it. No screen in the app should feel more
/// alive than this one.
///
/// Composed as an *arena*, not a page: a full-bleed dark field with the two
/// players' identity colors meeting at a tilted seam behind everything (see
/// [ClashBackdrop]), the HUD floating on top, and the answers as physical
/// slabs. There is no card, no app bar, and no scroll — the question and the
/// four ways to answer it are the entire screen.
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

  static const List<String> _optionLabels = ['A', 'B', 'C', 'D'];

  final String duelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final duelAsync = ref.watch(duelStreamProvider(duelId));
    final myUid = ref.watch(currentUserIdProvider);

    // Keeps `DuelPresenceController` alive for the lifetime of this screen —
    // it sends this player's heartbeat, watches the opponent's, and is the
    // single source of truth for which side (if either) has dropped. This
    // screen deliberately does no connection reasoning of its own; having
    // two places decide that is what let both players be told the *other*
    // one disconnected.
    final presence = ref.watch(duelPresenceProvider(duelId));

    ref.listen(duelStreamProvider(duelId), (previous, next) {
      final duel = next.value;
      if (duel != null && duel.status == DuelStatus.completed) {
        context.go(AppRoutes.duelResultPath(duelId));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.arenaDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.arenaGradient)),
          ),
          const Positioned.fill(child: ClashBackdrop()),
          SafeArea(
            child: duelAsync.when(
              loading: () => const Center(child: BrandedLoadingIndicator(onDark: true)),
              error: (error, _) => Center(child: _ArenaMessage(text: l10n.commonError)),
              data: (duel) {
                if (duel == null || myUid == null) {
                  return Center(child: _ArenaMessage(text: l10n.commonError));
                }

                final roundKey = (duelId: duelId, roundNumber: duel.currentRound);
                final roundAsync = ref.watch(roundStreamProvider(roundKey));

                return roundAsync.when(
                  loading: () => const Center(child: BrandedLoadingIndicator(onDark: true)),
                  error: (error, _) => Center(child: _ArenaMessage(text: l10n.commonError)),
                  data: (round) {
                    if (round == null) {
                      return const Center(child: BrandedLoadingIndicator(onDark: true));
                    }

                    final selectedIndex = ref.watch(selectedAnswerProvider(roundKey));
                    final hasAnswered = selectedIndex != null;
                    final isResolved = round.isResolved;
                    final myPoints = round.pointsAwarded[myUid] ?? 0;
                    final myAnswerIndex = round.playerAnswers[myUid];
                    final opponentId = duel.opponentIdFor(myUid);

                    return ResponsiveCenter(
                      maxWidth: 560,
                      child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: ArenaHud(
                            myName: duel.player1Id == myUid
                                ? duel.player1DisplayName
                                : duel.player2DisplayName,
                            myScore: duel.scoreFor(myUid),
                            opponentName: duel.opponentDisplayNameFor(myUid),
                            opponentScore: duel.scoreFor(opponentId),
                            center: isResolved
                                ? const ClashMark()
                                : DuelTimer(
                                    roundStartedAt: round.startedAt,
                                    onTimeUp: () {
                                      if (!hasAnswered) {
                                        ref
                                            .read(selectedAnswerProvider(roundKey).notifier)
                                            .select(-1);
                                      }
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _RoundChip(label: l10n.duelRoundOf(duel.currentRound, duel.totalRounds)),

                        // The question owns the vertical center. `Expanded`
                        // rather than a fixed block so a long question grows
                        // into the space instead of pushing the answers off.
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  duel.categoryName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      round.questionText,
                                      key: ValueKey(round.questionText),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        height: 1.28,
                                      ),
                                    ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0),
                                  ),
                                ),
                                if (isResolved) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  ScorePopup(
                                    pointsEarned: myPoints,
                                    wasCorrect: myAnswerIndex == round.correctAnswerIndex,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: Column(
                            children: [
                              for (var index = 0; index < round.options.length; index++) ...[
                                if (index > 0) const SizedBox(height: AppSpacing.sm),
                                AnswerOptionTile(
                                  label: round.options[index],
                                  indexLabel: index < _optionLabels.length
                                      ? _optionLabels[index]
                                      : '${index + 1}',
                                  visualState: _visualStateFor(
                                    index: index,
                                    isResolved: isResolved,
                                    correctIndex: round.correctAnswerIndex,
                                    myAnswerIndex: isResolved ? myAnswerIndex : selectedIndex,
                                  ),
                                  onTap: (hasAnswered || isResolved)
                                      ? null
                                      : () => ref
                                            .read(selectedAnswerProvider(roundKey).notifier)
                                            .select(index),
                                ),
                              ],
                            ],
                          ),
                        ),

                        _ArenaFooter(
                          waitingLabel: hasAnswered && !isResolved
                              ? l10n.duelWaitingOpponentAnswer
                              : null,
                          homeTurfLabel: duel.isHomeTurfDuel ? l10n.duelHomeTurfBonus : null,
                        ),
                      ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Exactly one of these can be non-null (see `DuelPresenceState`),
          // so the two players in a duel always see the two *different*
          // halves of the same disconnect, never the same half each.
          if (presence.selfSecondsRemaining != null)
            SelfDisconnectDialog(secondsRemaining: presence.selfSecondsRemaining!)
          else if (presence.opponentSecondsRemaining != null &&
              duelAsync.value != null &&
              myUid != null)
            OpponentDisconnectDialog(
              secondsRemaining: presence.opponentSecondsRemaining!,
              opponentName: duelAsync.value!.opponentDisplayNameFor(myUid),
            ),
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
    if (index == correctIndex) {
      // Same tile, two meanings: filled green if they got it, outlined green
      // if it was there to be got.
      return index == myAnswerIndex ? AnswerTileVisualState.correct : AnswerTileVisualState.missed;
    }
    if (index == myAnswerIndex) return AnswerTileVisualState.incorrect;
    return AnswerTileVisualState.neutral;
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.arenaRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
      ),
    );
  }
}

/// Fixed-height so the answer slabs above don't jump when a transient status
/// line appears or disappears between rounds.
class _ArenaFooter extends StatelessWidget {
  const _ArenaFooter({required this.waitingLabel, required this.homeTurfLabel});

  final String? waitingLabel;
  final String? homeTurfLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 30,
      child: Center(
        child: waitingLabel != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.onArenaMuted),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    waitingLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onArenaMuted),
                  ),
                ],
              )
            : homeTurfLabel != null
            ? Text(
                homeTurfLabel!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.gold),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ArenaMessage extends StatelessWidget {
  const _ArenaMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.onArenaMuted),
    );
  }
}
