import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/giants_logo.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen block shown when this build's `AppConstants.appVersion` is
/// older than `appControl/status.update.minVersion` — see `isVersionBelow`
/// and the redirect in `app_router.dart`. Unlike [MaintenanceScreen] this
/// can't clear itself: the only way past it is actually installing a newer
/// build, so the one action here opens [updateUrl] rather than waiting for a
/// flag to flip.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appControl = ref.watch(appControlProvider).value;
    final message = appControl?.updateMessage ?? '';
    final updateUrl = appControl?.updateUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.arenaDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.arenaGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GiantsMonogram(size: 96),
                  const SizedBox(height: AppSpacing.xl),
                  const Icon(Icons.system_update_rounded, size: 48, color: AppColors.gold),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.forceUpdateTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(color: AppColors.onArena),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message.trim().isNotEmpty ? message : l10n.forceUpdateDefaultMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                  ),
                  if (updateUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SlabButton(
                      label: l10n.forceUpdateButton,
                      icon: Icons.open_in_new_rounded,
                      background: AppColors.gold,
                      foreground: AppColors.onBrand,
                      expand: false,
                      onPressed: () => _openStore(updateUrl),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
