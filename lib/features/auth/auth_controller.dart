import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// All state/logic for this feature lives in this one file — screens only
/// call [signInWithEmail]/[signUpWithEmail]/[signInWithGoogle]/
/// [signInWithApple]/[signOut] and watch [state] for loading/error.
///
/// Actual "am I signed in" state is NOT held here — that's
/// `authStateChangesProvider` (a live stream from Firebase), watched by the
/// router to decide which screen to show. This controller only tracks the
/// in-flight status of the current sign-in/sign-up action, and is
/// responsible for the one bit of business logic auth has: creating the
/// Firestore user profile the very first time someone signs in.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthServiceProvider).signInWithEmail(email, password);
    });
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(firebaseAuthServiceProvider)
          .signUpWithEmail(email, password);
      await _ensureProfileExists(credential.user!, fallbackDisplayName: displayName);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      await _ensureProfileExists(credential.user!);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await ref.read(firebaseAuthServiceProvider).signInWithApple();
      await _ensureProfileExists(credential.user!);
    });
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthServiceProvider).signOut();
  }

  Future<void> _ensureProfileExists(User user, {String? fallbackDisplayName}) async {
    final UserRepository userRepository = ref.read(userRepositoryProvider);
    final existing = await userRepository.getUser(user.uid);
    if (existing != null) return;

    await userRepository.createInitialProfile(
      UserModel(
        uid: user.uid,
        displayName: user.displayName ?? fallbackDisplayName ?? user.email?.split('@').first ?? 'Player',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      ),
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);
