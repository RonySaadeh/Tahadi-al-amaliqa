import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahadi_al_amaliqa/core/providers/core_providers.dart';
import 'package:tahadi_al_amaliqa/features/duel/duel_controller.dart';
import 'package:tahadi_al_amaliqa/features/friends/friends_controller.dart';
import 'package:tahadi_al_amaliqa/features/notifications/notifications_controller.dart';

/// Every list the app scopes to "my data" takes a `myUid == null` branch —
/// used while signed out, and on every cold start for the moment before
/// `authStateChangesProvider` delivers its first event.
///
/// That branch used to return `const Stream.empty()`. A stream that closes
/// without emitting never moves a `StreamProvider` off `AsyncLoading`, so
/// the screens rendered their `loading:` skeletons instead of their empty
/// states — and because the stream had already closed, nothing would emit
/// later to correct it.
///
/// These tests pin the branch to "resolves to an empty list". They need no
/// Firestore: the null-uid branch returns before touching a repository.
void main() {
  ProviderContainer signedOutContainer() {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Resolves what the UI's `.when()` would actually branch on.
  Future<AsyncValue<List<T>>> read<T>(
    ProviderContainer container,
    StreamProvider<List<T>> provider,
  ) async {
    container.listen(provider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return container.read(provider);
  }

  test('recentDuelsProvider resolves to empty, not loading', () async {
    final c = signedOutContainer();
    final state = await read(c, recentDuelsProvider);

    expect(state, isA<AsyncData<List<Object?>>>(),
        reason: 'a skeleton here is the home screen bug');
    expect(state.value, isEmpty);
  });

  test('incomingInvitesProvider resolves to empty, not loading', () async {
    final c = signedOutContainer();
    final state = await read(c, incomingInvitesProvider);

    expect(state, isA<AsyncData<List<Object?>>>());
    expect(state.value, isEmpty);
  });

  test('myFriendshipsProvider resolves to empty, not loading', () async {
    final c = signedOutContainer();
    final state = await read(c, myFriendshipsProvider);

    expect(state, isA<AsyncData<List<Object?>>>(),
        reason: 'a skeleton here is the friends list bug');
    expect(state.value, isEmpty);
  });

  test('notificationsProvider resolves to empty, not loading', () async {
    final c = signedOutContainer();
    final state = await read(c, notificationsProvider);

    expect(state, isA<AsyncData<List<Object?>>>());
    expect(state.value, isEmpty);
  });

  test('the derived friends views resolve too', () async {
    final c = signedOutContainer();
    c.listen(myFriendshipsProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // These filter myFriendshipsProvider, so they inherit its state — the
    // friends list and the request badge both hung on the same root cause.
    expect(c.read(friendsListProvider).value, isEmpty);
    expect(c.read(incomingFriendRequestsProvider).value, isEmpty);
  });

  test('the unread badge reads 0 rather than hanging', () async {
    final c = signedOutContainer();
    c.listen(notificationsProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(c.read(unreadNotificationCountProvider), 0);
  });
}
