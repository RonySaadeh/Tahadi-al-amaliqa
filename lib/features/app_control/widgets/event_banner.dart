import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';

/// A dismissible strip shown above every tab (see `AppShell`) while
/// `appControl/status.event.active` is on and, if it has an end time,
/// still live — [AppControlModel.isEventLive]. Dismissing it only hides it
/// for this app session (an in-memory flag on this widget's state, not
/// persisted): reopening the app while the event is still live shows it
/// again, same as how a duel-invite badge doesn't need "have I already seen
/// this" tracking either — the event is short-lived by nature, so a returning
/// player is meant to be reminded.
class EventBanner extends ConsumerStatefulWidget {
  const EventBanner({super.key});

  @override
  ConsumerState<EventBanner> createState() => _EventBannerState();
}

class _EventBannerState extends ConsumerState<EventBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final appControl = ref.watch(appControlProvider).value;
    if (appControl == null || !appControl.isEventLive || _dismissed) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final endsAt = appControl.eventEndsAt;

    return Material(
      color: AppColors.gold,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: AppColors.onBrand, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appControl.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onBrand),
                    ),
                    if (appControl.eventDescription.trim().isNotEmpty)
                      Text(
                        appControl.eventDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrand),
                      ),
                    if (endsAt != null)
                      Text(
                        l10n.eventBannerEndsAt(Formatters.dateTime(endsAt, locale: locale)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onBrand.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close_rounded, color: AppColors.onBrand, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
