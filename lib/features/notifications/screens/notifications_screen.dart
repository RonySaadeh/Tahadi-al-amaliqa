import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../notifications_controller.dart';
import '../widgets/notification_tile.dart';

/// The notifications inbox opened from the bell on the home screen. Opening
/// it marks whatever's currently unread as read, same as most apps' bell
/// menus — the badge is about "anything new since I last looked", not a
/// per-item manual dismissal.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    // One-shot: the first time this build sees a loaded list, mark whatever
    // is unread as read. Guarded by `_markedRead` so it doesn't re-fire on
    // every rebuild as the list updates (e.g. once those writes land).
    notificationsAsync.whenData((notifications) {
      if (_markedRead) return;
      final unread = notifications.where((n) => !n.read);
      if (unread.isEmpty) return;
      _markedRead = true;
      final controller = ref.read(notificationsControllerProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final n in unread) {
          controller.markRead(n.id);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ResponsiveCenter(
        child: notificationsAsync.when(
          loading: () => const SkeletonList(),
          error: (_, _) => Center(child: Text(l10n.commonError)),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Text(l10n.notificationsEmpty, style: Theme.of(context).textTheme.bodyMedium),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => NotificationTile(notification: notifications[index]),
            );
          },
        ),
      ),
    );
  }
}
