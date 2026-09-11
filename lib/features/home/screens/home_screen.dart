import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../duel/duel_controller.dart';
import '../../notifications/notifications_controller.dart';
import '../home_controller.dart';
import '../widgets/arena_rating_header.dart';
import '../widgets/email_verification_banner.dart';
import '../widgets/recent_duel_tile.dart';

/// The home screen has no app bar. The rating header *is* the header — a
/// full-bleed arena field running to all three top edges, with the two
/// primary actions deliberately straddling its lower slant so the eye is
/// pulled across the boundary instead of down a list of separate blocks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// How far the action row is pulled up over the header's slanted edge.
  /// Subtracted again from the gap below it so nothing else shifts.
  static const double _overlap = 26;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final recentDuelsAsync = ref.watch(recentDuelsProvider);
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(recentDuelsProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const EmailVerificationBanner(),
            Stack(
              children: [
                userAsync.when(
                  data: (user) => ArenaRatingHeader(
                    displayName: user?.displayName ?? '',
                    elo: user?.elo ?? 0,
                    wins: user?.wins ?? 0,
                    losses: user?.losses ?? 0,
                  ),
                  loading: () => const SizedBox(
                    height: 240,
                    child: ColoredBox(color: AppColors.arenaDark),
                  ),
                  error: (_, _) => const SizedBox(
                    height: 240,
                    child: ColoredBox(color: AppColors.arenaDark),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: _NotificationBell(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ResponsiveCenter(
                  child: Row(
                    children: [
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeQuickMatch,
                          icon: Icons.bolt_rounded,
                          gradient: AppColors.primaryGradient,
                          background: AppColors.primary,
                          onPressed: () => context.go(AppRoutes.duelLobby),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeChallengeFriend,
                          icon: Icons.people_alt_rounded,
                          background: AppColors.gold,
                          foreground: AppColors.onBrand,
                          onPressed: () => context.go(AppRoutes.duelLobby),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ResponsiveCenter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeRecentDuels.toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      recentDuelsAsync.when(
                        data: (duels) {
                          if (duels.isEmpty || myUid == null) {
                            return _EmptyDuels(message: l10n.homeNoRecentDuels);
                          }
                          return Column(
                            children: duels
                                .map(
                                  (d) => RecentDuelTile(
                                    duel: d,
                                    myUid: myUid,
                                    onTap: () => context.push(
                                      AppRoutes.playerProfilePath(d.opponentIdFor(myUid)),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () => const SkeletonList(itemCount: 3),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the notifications inbox. Overlaid on the arena header rather than
/// added as an `AppBar` — this screen deliberately has none (see the class
/// doc above) — so a single icon is the whole footprint this adds.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text('$unreadCount'),
      backgroundColor: AppColors.gold,
      textColor: AppColors.onBrand,
      child: IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_rounded, color: Colors.white),
        tooltip: l10n.notificationsTitle,
      ),
    );
  }
}

class _EmptyDuels extends StatelessWidget {
  const _EmptyDuels({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_kabaddi_rounded, size: 34, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
