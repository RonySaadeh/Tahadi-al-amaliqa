import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/duel_invite_model.dart';
import '../../../l10n/app_localizations.dart';

/// One pending incoming challenge shown at the top of the duel lobby.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.invite, required this.onAccept, required this.onDecline});

  final DuelInviteModel invite;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invite.fromDisplayName, style: Theme.of(context).textTheme.titleMedium),
                  Text(invite.categoryName, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(
              onPressed: onDecline,
              icon: const Icon(Icons.close_rounded),
              tooltip: l10n.commonCancel,
            ),
            FilledButton(onPressed: onAccept, child: Text(l10n.commonConfirm)),
          ],
        ),
      ),
    );
  }
}
