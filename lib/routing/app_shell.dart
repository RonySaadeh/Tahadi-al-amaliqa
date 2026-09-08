import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'app_router.dart';

/// The bottom-nav scaffold wrapping the 5 main tabs. Full-screen flows
/// (live duel, results) deliberately live outside this shell — see
/// `app_router.dart`.
class AppShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabs[index]),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l10n.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.bolt_rounded), label: l10n.navDuel),
          BottomNavigationBarItem(icon: const Icon(Icons.leaderboard_rounded), label: l10n.navLeaderboard),
          BottomNavigationBarItem(icon: const Icon(Icons.flag_rounded), label: l10n.navHomeTurf),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: l10n.navProfile),
        ],
      ),
    );
  }
}
