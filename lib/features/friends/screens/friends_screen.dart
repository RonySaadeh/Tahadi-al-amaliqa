import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../duel/widgets/challenge_category_sheet.dart';
import '../friends_controller.dart';
import '../widgets/friend_request_card.dart';
import '../widgets/friend_row.dart';

/// Search for players, send/accept/decline friend requests, and see your
/// friends list with who's online right now. One plain scrolling page —
/// same `AppBar` treatment as `HomeTurfScreen`, no extra chrome.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(friendSearchControllerProvider.notifier).search(value);
    });
    setState(() {}); // refreshes the clear button / empty-vs-searching branch
  }

  Future<void> _showChallengeSheet(String friendUid) {
    return showChallengeCategorySheet(context, toUserId: friendUid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myUid = ref.watch(currentUserIdProvider);
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.friendsTitle)),
      body: ResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.friendsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(friendSearchControllerProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: isSearching || myUid == null
                    ? _SearchResults(myUid: myUid, onChallenge: _showChallengeSheet)
                    : _FriendsOverview(myUid: myUid, onChallenge: _showChallengeSheet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.myUid, required this.onChallenge});

  final String? myUid;
  final ValueChanged<String> onChallenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(friendSearchControllerProvider);
    final myFriendships = ref.watch(myFriendshipsProvider).value ?? const [];

    return resultsAsync.when(
      loading: () => const SkeletonList(itemCount: 4),
      error: (_, _) => Center(child: Text(l10n.commonError)),
      data: (results) {
        if (myUid == null) return const SizedBox.shrink();
        if (results.isEmpty) {
          return Center(
            child: Text(l10n.friendsSearchNoResults, style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            final relation = friendRelationWith(myFriendships, myUid!, user.uid);
            return _SearchResultRow(user: user, relation: relation, onChallenge: () => onChallenge(user.uid));
          },
        );
      },
    );
  }
}

class _SearchResultRow extends ConsumerWidget {
  const _SearchResultRow({required this.user, required this.relation, required this.onChallenge});

  final UserModel user;
  final FriendRelation relation;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = user.displayName.trim();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.playerProfilePath(user.uid)),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.16),
          image: user.photoUrl != null
              ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: user.photoUrl != null
            ? null
            : Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: switch (relation) {
        FriendRelation.none => SlabButton(
          label: l10n.friendsSendRequest,
          expand: false,
          fontSize: 13,
          verticalPadding: AppSpacing.sm,
          onPressed: () => ref.read(friendsControllerProvider.notifier).sendRequest(user.uid),
        ),
        FriendRelation.requestSent => SlabButton(
          label: l10n.friendsRequestSent,
          expand: false,
          fontSize: 13,
          verticalPadding: AppSpacing.sm,
          background: AppColors.surfaceRaised,
          foreground: AppColors.textSecondary,
          depthColor: AppColors.surfaceBorder,
          onPressed: null,
        ),
        FriendRelation.requestReceived => Text(
          l10n.friendsRequestReceivedHint,
          style: theme.textTheme.bodySmall,
        ),
        FriendRelation.friends => SlabButton(
          label: l10n.friendsChallenge,
          expand: false,
          fontSize: 13,
          verticalPadding: AppSpacing.sm,
          onPressed: onChallenge,
        ),
      },
    );
  }
}

class _FriendsOverview extends ConsumerWidget {
  const _FriendsOverview({required this.myUid, required this.onChallenge});

  final String myUid;
  final ValueChanged<String> onChallenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final friendsAsync = ref.watch(friendsListProvider);

    return ListView(
      children: [
        incomingAsync.when(
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.friendsRequestsTitle.toUpperCase(), style: theme.textTheme.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                for (final request in requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FriendRequestCard(
                      fromDisplayName: request.fromDisplayName,
                      onAccept: () => ref
                          .read(friendsControllerProvider.notifier)
                          .respondToRequest(otherUserId: request.fromUserId, accept: true),
                      onDecline: () => ref
                          .read(friendsControllerProvider.notifier)
                          .respondToRequest(otherUserId: request.fromUserId, accept: false),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        Text(l10n.friendsMyFriendsTitle.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        friendsAsync.when(
          loading: () => const SkeletonList(itemCount: 4),
          error: (_, _) => Text(l10n.commonError),
          data: (friends) {
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    l10n.friendsNoFriends,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final friendship in friends)
                  FriendRow(
                    friendUid: friendship.otherUserId(myUid),
                    onTap: () =>
                        context.push(AppRoutes.playerProfilePath(friendship.otherUserId(myUid))),
                    onChallenge: () => onChallenge(friendship.otherUserId(myUid)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
