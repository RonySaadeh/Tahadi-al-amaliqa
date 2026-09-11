import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// One pending incoming friend request — same `Card`/row shape as
/// `InviteCard` (the duel-challenge equivalent), shown at the top of the
/// friends list the same way `InviteCard` sits at the top of the duel
/// lobby.
class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.fromDisplayName,
    required this.onAccept,
    required this.onDecline,
  });

  final String fromDisplayName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.friendsRequestBody(fromDisplayName),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onDecline, child: Text(l10n.commonDecline)),
            FilledButton(onPressed: onAccept, child: Text(l10n.commonAccept)),
          ],
        ),
      ),
    );
  }
}
