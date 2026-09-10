import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/duel_repository.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/user_repository.dart';
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

// --- Connectivity ---

/// Whether the device currently has real internet access (not just a radio
/// connected to something — see `ConnectivityService`). Emits an immediate
/// initial check, then live updates as the network changes. Used by the
/// router to hold signed-out users on the splash screen instead of showing
/// a login form that has nothing to talk to.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkConnection();
  yield* service.onConnectivityChanged;
});
