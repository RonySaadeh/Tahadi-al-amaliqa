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

/// The nav scaffold wrapping the 5 main tabs. Full-screen flows (live duel,
/// results) deliberately live outside this shell — see `app_router.dart`.
///
/// The nav itself is width-adaptive: a bottom bar on a phone, a side
/// `NavigationRail` once there's tablet/desktop-web width to spare (see
/// `AppBreakpoints`) — a bottom bar stretched across a wide browser window
/// or tablet in landscape reads as a mobile page that never got adapted.
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

  static const _tabs = [
    AppRoutes.home,
    AppRoutes.duelLobby,
    AppRoutes.leaderboard,
    AppRoutes.homeTurf,
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

    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOffline =
        connectivityAsync.hasValue && connectivityAsync.value == false;

    final body = isOffline ? _OfflineLoading(l10n: l10n) : child;

    final destinations = [
      (icon: Icons.home_rounded, label: l10n.navHome),
      (icon: Icons.bolt_rounded, label: l10n.navDuel),
      (icon: Icons.leaderboard_rounded, label: l10n.navLeaderboard),
      (icon: Icons.flag_rounded, label: l10n.navHomeTurf),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabs[index]),
        items: [
          for (final d in destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
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
