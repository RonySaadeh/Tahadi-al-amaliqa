import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/duel_repository.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../constants/app_constants.dart';
import '../services/cloud_functions_service.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

/// Single place where every service/repository gets wired up.
///
/// Feature controllers depend on the *repository* providers, never on
/// `FirebaseAuth.instance` or `FirebaseFirestore.instance` directly — that
/// keeps Firebase itself swappable/mockable and stops SDK calls from
/// leaking into UI/state-management code. See each feature's README for how
/// its controller uses these.

// --- Low-level services ---
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) => FirebaseAuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>(
  (ref) => CloudFunctionsService(),
);
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

// --- Repositories ---
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(firestoreService: ref.watch(firestoreServiceProvider)),
);
final duelRepositoryProvider = Provider<DuelRepository>(
  (ref) => DuelRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    cloudFunctions: ref.watch(cloudFunctionsServiceProvider),
  ),
);
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    cloudFunctions: ref.watch(cloudFunctionsServiceProvider),
  ),
);
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(firestoreService: ref.watch(firestoreServiceProvider)),
);

// --- Auth state ---

/// Raw Firebase auth stream. Most of the app should watch
/// [currentUserIdProvider] instead — this is mainly for the router redirect
/// and the auth controller itself.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

/// Null when signed out. Convenient shortcut used all over the app to scope
/// queries to "my data" (e.g. `watchUser(ref.watch(currentUserIdProvider)!)`).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).value?.uid;
});

/// A one-time fetch of *another* player's profile by uid — e.g. an
/// opponent's category-win count on the pre-duel VS screen, or viewing their
/// profile from a past duel or the leaderboard. A `Future`, not a `Stream`:
/// these are read-once snapshots, unlike [currentUserProvider]'s live watch
/// on the signed-in player's own document.
final userByIdProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUser(uid);
});

// --- Connectivity ---

/// Whether the device currently has real internet access (not just a radio
/// connected to something — see `ConnectivityService`). Emits an immediate
/// initial check, then live updates as the network changes. Used by the
/// router to hold every cold start on the splash screen — signed in or not
/// — until the device is actually online, instead of letting a
/// disconnected device through to a login form or an app it can't talk to.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkConnection();
  yield* service.onConnectivityChanged;
});

/// Resolves to `true` after [AppConstants.splashMinDurationMs] have passed
/// since this provider was first read. The router's redirect holds every
/// cold start on the splash screen until this (in addition to auth and
/// connectivity) has resolved, so the branded loading moment always shows
/// for a beat instead of flashing past in a single frame when auth resolves
/// instantly from a cached session.
final splashMinDurationElapsedProvider = FutureProvider<bool>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: AppConstants.splashMinDurationMs));
  return true;
});
