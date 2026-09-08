import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/core_providers.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/duel/screens/duel_lobby_screen.dart';
import '../features/duel/screens/duel_result_screen.dart';
import '../features/duel/screens/live_duel_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home_turf/screens/category_detail_screen.dart';
import '../features/home_turf/screens/home_turf_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'app_shell.dart';

/// All named routes in one place. Every screen file is otherwise unaware of
/// how it was navigated to — it just declares its route path here.
class AppRoutes {
  const AppRoutes._();

  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String duelLobby = '/duel';
  static const String leaderboard = '/leaderboard';
  static const String homeTurf = '/home-turf';
  static const String homeTurfCategory = '/home-turf/:categoryId';
  static const String profile = '/profile';
  static const String liveDuel = '/duel/:duelId/live';
  static const String duelResult = '/duel/:duelId/result';

  static String homeTurfCategoryPath(String categoryId) => '/home-turf/$categoryId';
  static String liveDuelPath(String duelId) => '/duel/$duelId/live';
  static String duelResultPath(String duelId) => '/duel/$duelId/result';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isSignedIn = ref.read(currentUserIdProvider) != null;
      final isGoingToWelcome = state.matchedLocation == AppRoutes.welcome;

      if (!isSignedIn && !isGoingToWelcome) return AppRoutes.welcome;
      if (isSignedIn && isGoingToWelcome) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),

      // Full-screen duel routes live outside the bottom-nav shell — the
      // live duel screen especially should have zero chrome competing for
      // attention.
      GoRoute(
        path: AppRoutes.liveDuel,
        builder: (context, state) => LiveDuelScreen(duelId: state.pathParameters['duelId']!),
      ),
      GoRoute(
        path: AppRoutes.duelResult,
        builder: (context, state) => DuelResultScreen(duelId: state.pathParameters['duelId']!),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          GoRoute(path: AppRoutes.duelLobby, builder: (context, state) => const DuelLobbyScreen()),
          GoRoute(path: AppRoutes.leaderboard, builder: (context, state) => const LeaderboardScreen()),
          GoRoute(path: AppRoutes.homeTurf, builder: (context, state) => const HomeTurfScreen()),
          GoRoute(
            path: AppRoutes.homeTurfCategory,
            builder: (context, state) =>
                CategoryDetailScreen(categoryId: state.pathParameters['categoryId']!),
          ),
          GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's `authStateChangesProvider` stream into the
/// `Listenable` go_router's `refreshListenable` expects, so navigation
/// re-evaluates the redirect the instant sign-in state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _subscription = _ref.listen(authStateChangesProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
