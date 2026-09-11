import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../duel/duel_controller.dart';
import '../../friends/friends_controller.dart';
import '../notifications_controller.dart';

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
          await ref
              .read(duelControllerProvider.notifier)
              .respondToChallenge(inviteId: notification.relatedId, accept: accept);
      }
    } catch (_) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    }
    if (!notification.read) {
      await ref.read(notificationsControllerProvider).markRead(notification.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final body = switch (notification.type) {
      NotificationType.friendRequest => l10n.friendsRequestBody(notification.fromDisplayName),
      NotificationType.duelChallenge => l10n.notificationsChallengeBody(notification.fromDisplayName),
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
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                ),
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
