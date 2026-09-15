import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../duel/duel_controller.dart';
import '../../friends/friends_controller.dart';

/// One entry in the notifications inbox — a friend request or a duel
/// challenge, each with inline Accept/Decline that calls straight into the
/// same controllers the Friends screen and duel lobby already use, so
/// responding here and responding there are the exact same action.
class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.notification});

  final NotificationModel notification;

  Future<void> _respond(BuildContext context, WidgetRef ref, {required bool accept}) async {
    try {
      switch (notification.type) {
        case NotificationType.friendRequest:
          await ref
              .read(friendsControllerProvider.notifier)
              .respondToRequest(otherUserId: notification.fromUserId, accept: accept);
        case NotificationType.duelChallenge:
          final duelId = await ref
              .read(duelControllerProvider.notifier)
              .respondToChallenge(inviteId: notification.relatedId, accept: accept);
          // Accepting from the Notifications tab used to be a dead end —
          // this is the same navigation `HomeScreen`'s inline invite card
          // already does for the same accept action.
          if (duelId != null && context.mounted) {
            context.push(AppRoutes.duelIntroPath(duelId));
          }
        case NotificationType.announcement:
          break; // No response action — see the early return in build() below.
      }
    } catch (_) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    }
    // No `markRead` call here: responding to a friend request or duel
    // challenge now deletes this notification doc server-side (see
    // `respondToFriendRequest`/`respondToDuelChallenge`), so marking it read
    // afterward would just throw on a doc that's already gone.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unreadDot = !notification.read
        ? Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
          )
        : null;

    // An admin's broadcast is free-text and one-way — it carries its own
    // title/message rather than the templated "{name} did X" body every
    // other type gets, and there's nothing to Accept/Decline.
    if (notification.type == NotificationType.announcement) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.read ? null : AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unreadDot != null) unreadDot,
            const Icon(Icons.campaign_rounded, size: 20, color: AppColors.gold),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (notification.title?.trim().isNotEmpty ?? false) ? notification.title! : l10n.notificationsTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(notification.message ?? '', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final body = switch (notification.type) {
      NotificationType.friendRequest => l10n.friendsRequestBody(notification.fromDisplayName),
      NotificationType.duelChallenge => l10n.notificationsChallengeBody(notification.fromDisplayName),
      NotificationType.announcement => '', // handled above
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification.read ? null : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unreadDot != null) unreadDot,
              Expanded(child: Text(body, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _respond(context, ref, accept: false),
                child: Text(l10n.commonDecline),
              ),
              FilledButton(
                onPressed: () => _respond(context, ref, accept: true),
                child: Text(l10n.commonAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
