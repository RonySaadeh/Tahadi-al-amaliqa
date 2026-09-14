import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/core_providers.dart';
import '../core/utils/version_compare.dart';
import '../features/app_control/screens/app_control_screen.dart';
import '../features/app_control/screens/force_update_screen.dart';
import '../features/app_control/screens/maintenance_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/duel/screens/duel_intro_screen.dart';
import '../features/duel/screens/duel_result_screen.dart';
import '../features/duel/screens/live_duel_screen.dart';
import '../features/friends/screens/friends_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/leaderboard/screens/leaderboard_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/player_profile_screen.dart';
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
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
  static const String playerProfile = '/players/:uid';
  static const String friends = '/friends';
  static const String notifications = '/notifications';
  static const String appControl = '/app-control';
  static const String maintenance = '/maintenance';
  static const String updateRequired = '/update-required';
  static const String duelIntro = '/duel/:duelId/intro';
  static const String liveDuel = '/duel/:duelId/live';
  static const String duelResult = '/duel/:duelId/result';

  static String playerProfilePath(String uid) => '/players/$uid';
  static String duelIntroPath(String duelId) => '/duel/$duelId/intro';
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

      // Every cold start sits on the splash screen for at least this long,
      // regardless of how fast auth/connectivity resolve — a deliberate,
      // branded loading beat instead of an instant flash. See
      // `splashMinDurationElapsedProvider`.
      final minDurationElapsed = ref.read(splashMinDurationElapsedProvider).value == true;
      if (isGoingToSplash && !minDurationElapsed) return null;

      // Every cold start — signed in or not — is held on the splash screen
      // until the device has real internet access. This only gates *entry*
      // to the app: a session that already made it past this check and is
      // now inside the app relies on Firestore's own offline cache to ride
      // out a momentary drop, with `AppShell` showing its own "reconnecting"
      // loading screen for that case instead of bouncing back to splash —
      // see `app_shell.dart`.
      final isConnected = ref.read(connectivityStatusProvider).value;
      if (isConnected != true) {
        return isGoingToSplash ? null : AppRoutes.splash;
      }

      // App Control gating: maintenance mode and a force-required update
      // both block the entire app, signed in or not — see `AppControlModel`
      // and `features/app_control/`. Read as `.value` (fires again the
      // instant an admin toggles either flag, via `appControlProvider`'s
      // `ref.listen` in `_AppRefreshNotifier` below) and fails *open* — a
      // still-loading or errored snapshot never blocks the app, since this
      // is an operational switch, not a security boundary, and shouldn't be
      // able to lock everyone out over a slow first read.
      final appControl = ref.read(appControlProvider).value;
      final isGoingToMaintenance = state.matchedLocation == AppRoutes.maintenance;
      final isGoingToUpdateRequired = state.matchedLocation == AppRoutes.updateRequired;

      if (appControl?.maintenanceEnabled == true) {
        return isGoingToMaintenance ? null : AppRoutes.maintenance;
      }
      if (appControl?.forceUpdateEnabled == true &&
          isVersionBelow(AppConstants.appVersion, appControl!.minVersion)) {
        return isGoingToUpdateRequired ? null : AppRoutes.updateRequired;
      }
      // Neither block applies (any more) — leave a gate screen the instant
      // it clears, same as the destination it would have otherwise reached.
      if (isGoingToMaintenance || isGoingToUpdateRequired) {
        return isSignedIn ? AppRoutes.home : AppRoutes.welcome;
      }

      if (isSignedIn) {
        if (minDurationElapsed && (isGoingToSplash || isGoingToWelcome)) return AppRoutes.home;
        return null;
      }

      if (!isGoingToWelcome) return AppRoutes.welcome;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.maintenance, builder: (context, state) => const MaintenanceScreen()),
      GoRoute(path: AppRoutes.updateRequired, builder: (context, state) => const ForceUpdateScreen()),

      // Full-screen duel routes live outside the bottom-nav shell — the
      // live duel screen especially should have zero chrome competing for
      // attention. The intro screen joins them: it hands off straight into
      // `LiveDuelScreen`, so popping the nav shell back in between would be
      // pointless churn.
      GoRoute(
        path: AppRoutes.duelIntro,
        builder: (context, state) => DuelIntroScreen(duelId: state.pathParameters['duelId']!),
      ),
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
          GoRoute(path: AppRoutes.leaderboard, builder: (context, state) => const LeaderboardScreen()),
          GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
          GoRoute(
            path: AppRoutes.playerProfile,
            builder: (context, state) => PlayerProfileScreen(uid: state.pathParameters['uid']!),
          ),
          GoRoute(path: AppRoutes.friends, builder: (context, state) => const FriendsScreen()),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.appControl,
            builder: (context, state) => const AppControlScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's `authStateChangesProvider`, `connectivityStatusProvider`,
/// `splashMinDurationElapsedProvider`, and `appControlProvider` into the
/// `Listenable` go_router's `refreshListenable` expects, so navigation
/// re-evaluates the redirect the instant sign-in state, connectivity, the
/// splash timer, or an admin's maintenance/force-update toggle changes.
class _AppRefreshNotifier extends ChangeNotifier {
  _AppRefreshNotifier(this._ref) {
    _authSubscription = _ref.listen(authStateChangesProvider, (previous, next) {
      notifyListeners();
    });
    _connectivitySubscription = _ref.listen(connectivityStatusProvider, (previous, next) {
      notifyListeners();
    });
    _splashMinDurationSubscription = _ref.listen(splashMinDurationElapsedProvider, (previous, next) {
      notifyListeners();
    });
    _appControlSubscription = _ref.listen(appControlProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _authSubscription;
  late final ProviderSubscription<AsyncValue<bool>> _connectivitySubscription;
  late final ProviderSubscription<AsyncValue<bool>> _splashMinDurationSubscription;
  late final ProviderSubscription<AsyncValue<dynamic>> _appControlSubscription;

  @override
  void dispose() {
    _authSubscription.close();
    _connectivitySubscription.close();
    _splashMinDurationSubscription.close();
    _appControlSubscription.close();
    super.dispose();
  }
}
