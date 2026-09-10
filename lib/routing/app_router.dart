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
import '../features/splash/screens/splash_screen.dart';
import 'app_shell.dart';

/// All named routes in one place. Every screen file is otherwise unaware of
/// how it was navigated to — it just declares its route path here.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
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
  final authNotifier = _AppRefreshNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Reads providers directly via ref.read rather than through derived
      // ones like currentUserIdProvider: notifyListeners() below fires
      // synchronously from within the ref.listen callbacks that react to
      // these same providers, and at that point Riverpod hasn't yet
      // propagated the change to anything derived from them — reading a
      // derived provider here would see a stale value and fail to redirect.
      final isSignedIn = ref.read(authStateChangesProvider).value != null;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToWelcome = state.matchedLocation == AppRoutes.welcome;

      // Signed-in sessions never wait on a connectivity check here — this
      // gate exists to stop a *signed-out* user from being shown a login
      // form with no internet to submit it to, not to re-litigate an
      // already-authenticated session every time the radio blips. Once
      // inside the app, Firestore's own offline cache carries a real
      // session through a momentary drop.
      if (isSignedIn) {
        if (isGoingToSplash || isGoingToWelcome) return AppRoutes.home;
        return null;
      }

      // Signed out: hold on the splash screen until we know the device has
      // real internet access, instead of ever showing the welcome/login
      // form when it has nothing to reach.
      final isConnected = ref.read(connectivityStatusProvider).value;
      if (isConnected != true) {
        return isGoingToSplash ? null : AppRoutes.splash;
      }
      if (!isGoingToWelcome) return AppRoutes.welcome;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
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

/// Bridges Riverpod's `authStateChangesProvider` and `connectivityStatusProvider`
/// streams into the `Listenable` go_router's `refreshListenable` expects, so
/// navigation re-evaluates the redirect the instant either sign-in state or
/// connectivity changes.
class _AppRefreshNotifier extends ChangeNotifier {
  _AppRefreshNotifier(this._ref) {
    _authSubscription = _ref.listen(authStateChangesProvider, (previous, next) {
      notifyListeners();
    });
    _connectivitySubscription = _ref.listen(connectivityStatusProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _authSubscription;
  late final ProviderSubscription<AsyncValue<bool>> _connectivitySubscription;

  @override
  void dispose() {
    _authSubscription.close();
    _connectivitySubscription.close();
    super.dispose();
  }
}
