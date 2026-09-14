import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/core_providers.dart';
import '../core/theme/app_breakpoints.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/branded_loading_indicator.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';

/// The nav scaffold wrapping the 4 main tabs. Full-screen flows (live duel,
/// results) deliberately live outside this shell — see `app_router.dart`.
///
/// The nav itself is width-adaptive: a bottom bar with a raised center
/// button on a phone (see `_PhoneBottomBar`), a side `NavigationRail` once
/// there's tablet/desktop-web width to spare (see `AppBreakpoints`) — a
/// bottom bar stretched across a wide browser window or tablet in landscape
/// reads as a mobile page that never got adapted.
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
        body: Row(
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
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: _PhoneBottomBar(
        currentIndex: currentIndex,
        onSelect: (index) => context.go(_tabs[index]),
        l10n: l10n,
      ),
    );
  }
}

/// Home+Duel sits raised above the bar line as the tab's "main character" —
/// everything you'd come to this app to *do* starts there, so it gets more
/// visual weight than a fifth icon in a row would give it. Leaderboard and
/// Friends sit to its left, Profile to its right, on a plain flat bar.
///
/// Built by hand rather than with `BottomNavigationBar`: that widget lays
/// every item out identically in a `Row`, with no way for one of them to be
/// larger than the rest or to sit above the bar's own top edge.
class _PhoneBottomBar extends StatelessWidget {
  const _PhoneBottomBar({required this.currentIndex, required this.onSelect, required this.l10n});

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;

  static const double _barHeight = 64;
  static const double _raisedButtonSize = 58;

  /// How far the raised button's center sits above the bar's own top edge.
  static const double _raise = 22;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + bottomInset + _raise,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: _barHeight + bottomInset,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            // Two equal-flex halves around a fixed-width center gap, NOT
            // three equal-flex items with the gap as a fourth slot. Three
            // equal slots puts the gap at 2/3 across the row (two items
            // left of it, one right), while the raised button above is
            // centered on the *full* bar width — those two centers don't
            // match, which is what read as "misaligned". Two equal halves
            // guarantee the gap between them sits at the row's true
            // center, matching the button every time regardless of how
            // many icons sit in each half.
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _BarItem(
                          icon: Icons.leaderboard_rounded,
                          label: l10n.navLeaderboard,
                          selected: currentIndex == 1,
                          onTap: () => onSelect(1),
                        ),
                      ),
                      Expanded(
                        child: _BarItem(
                          icon: Icons.people_alt_rounded,
                          label: l10n.navFriends,
                          selected: currentIndex == 2,
                          onTap: () => onSelect(2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Reserves the center slot the raised button floats above —
                // an empty spacer, not a fifth flat item.
                const SizedBox(width: _raisedButtonSize + AppSpacing.lg),
                Expanded(
                  child: _BarItem(
                    icon: Icons.person_rounded,
                    label: l10n.navProfile,
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _RaisedHomeButton(
              label: l10n.navHome,
              selected: currentIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tab bar's "main character" — a gold-ringed violet slab lifted above
/// the bar line, echoing the app's own monogram mark (see
/// `core/widgets/giants_logo.dart`) rather than looking like a generic FAB.
/// Dims to a flat icon when not selected so it doesn't out-shout the rest
/// of the bar while you're actually on another tab.
class _RaisedHomeButton extends StatelessWidget {
  const _RaisedHomeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _size = _PhoneBottomBar._raisedButtonSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _size,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : AppColors.surfaceRaised,
              border: Border.all(color: AppColors.gold, width: selected ? 2.5 : 1.5),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: 1)]
                  : null,
            ),
            child: Icon(
              Icons.home_rounded,
              color: selected ? Colors.white : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
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
