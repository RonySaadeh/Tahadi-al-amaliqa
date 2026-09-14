import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/core_providers.dart';
import '../core/theme/app_breakpoints.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/branded_loading_indicator.dart';
import '../features/app_control/widgets/event_banner.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';

/// The nav scaffold wrapping the 4 main tabs. Full-screen flows (live duel,
/// results) deliberately live outside this shell — see `app_router.dart`.
///
/// The nav itself is width-adaptive: a dark full-bleed "arena" bar on a
/// phone (see `_PhoneBottomBar`), a side `NavigationRail` once there's
/// tablet/desktop-web width to spare (see `AppBreakpoints`) — a bottom bar
/// stretched across a wide browser window or tablet in landscape reads as a
/// mobile page that never got adapted.
///
/// Also owns the "you're offline" loading screen for an already-signed-in
/// session: the router deliberately never bounces a signed-in user back to
/// splash/login over a connectivity blip (see its redirect), so this is
/// where that blip actually becomes visible — blocking every tab behind a
/// full-screen loader until the connection returns. `LiveDuelScreen` and
/// `DuelResultScreen` live outside this shell and handle connectivity loss
/// themselves (the 35-second reconnect flow), so they're unaffected.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// Rail order (desktop/tablet). The raised-button treatment below is
  /// phone-only — see the class doc — so the rail just lists Home first
  /// like any other destination, with no special emphasis; "the main
  /// character" only really reads as a bottom-bar idiom.
  static const _tabs = [
    AppRoutes.home,
    AppRoutes.leaderboard,
    AppRoutes.friends,
    AppRoutes.profile,
  ];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    // Keeps the signed-in player's presence heartbeat alive for as long as
    // they're anywhere in the main app shell — see `presenceControllerProvider`.
    ref.watch(presenceControllerProvider);

    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOffline =
        connectivityAsync.hasValue && connectivityAsync.value == false;

    final body = isOffline ? _OfflineLoading(l10n: l10n) : child;

    final destinations = [
      (icon: Icons.home_rounded, label: l10n.navHome),
      (icon: Icons.leaderboard_rounded, label: l10n.navLeaderboard),
      (icon: Icons.people_alt_rounded, label: l10n.navFriends),
      (icon: Icons.person_rounded, label: l10n.navProfile),
    ];

    if (!context.isCompactWidth) {
      final extended = context.isExpandedWidth;
      return Scaffold(
        body: Column(
          children: [
            const EventBanner(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) => context.go(_tabs[index]),
                    extended: extended,
                    labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const EventBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: _PhoneBottomBar(
        currentIndex: currentIndex,
        onSelect: (index) => context.go(_tabs[index]),
        l10n: l10n,
      ),
    );
  }
}

/// A full-bleed dark "arena" slab, matching the splash/hero regions rather
/// than a light Material bar — all four tabs sit at equal weight in one
/// row. The selected tab gets its own gold-bordered gradient slab pill with
/// a hard offset shadow (the same zero-blur depth language as
/// [SlabButton](../core/widgets/slab_button.dart)), instead of a floating
/// circular button breaking the bar's top edge.
class _PhoneBottomBar extends StatelessWidget {
  const _PhoneBottomBar({required this.currentIndex, required this.onSelect, required this.l10n});

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;

  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      (icon: Icons.home_rounded, label: l10n.navHome),
      (icon: Icons.leaderboard_rounded, label: l10n.navLeaderboard),
      (icon: Icons.people_alt_rounded, label: l10n.navFriends),
      (icon: Icons.person_rounded, label: l10n.navProfile),
    ];

    return Container(
      height: _barHeight + bottomInset,
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: bottomInset + AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.arenaDark,
        border: Border(top: BorderSide(color: AppColors.arenaRaised, width: 2)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _BarItem(
                icon: items[i].icon,
                label: items[i].label,
                selected: currentIndex == i,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// One tab. Selected state is a gold-bordered violet slab pill with a hard
/// offset shadow sitting *behind* the icon+label; unselected tabs are just
/// a muted icon+label on the bare dark bar.
class _BarItem extends StatelessWidget {
  const _BarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _depth = 3;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.onArenaMuted;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        if (selected) ...[
          const SizedBox(width: AppSpacing.xs),
          // `Flexible` + ellipsis, not a bare `Text`: four equal tabs leave
          // very little width per pill on a narrow phone, and a longer
          // localized label (e.g. "LEADERBOARD") would otherwise overflow
          // the bar rather than just truncating.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          margin: selected ? EdgeInsets.zero : const EdgeInsets.only(bottom: _depth),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: selected ? Border.all(color: AppColors.gold, width: 1.5) : null,
            boxShadow: selected
                ? [const BoxShadow(color: AppColors.primaryDim, offset: Offset(0, _depth), blurRadius: 0)]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Full-screen "reconnecting" state shown in place of the active tab while
/// this signed-in session has no real internet access. Purely reactive —
/// there's nothing to retry manually here, since `connectivityStatusProvider`
/// already listens for the OS reporting the radio back on and re-verifies it
/// with a real DNS lookup; the underlying tab just reappears the instant
/// that resolves.
class _OfflineLoading extends StatelessWidget {
  const _OfflineLoading({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
                BrandedLoadingIndicator(message: l10n.appOfflineMessage),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
