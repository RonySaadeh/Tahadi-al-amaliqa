import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/giants_logo.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen block shown in place of the entire app while
/// `appControl/status.maintenance.enabled` is true — see the redirect in
/// `app_router.dart`. Deliberately outside the nav shell and has no way out
/// other than the flag itself flipping back off, which the router's
/// `refreshListenable` picks up live (no manual retry button needed).
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final message = ref.watch(appControlProvider).value?.maintenanceMessage ?? '';

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
                  const Icon(Icons.construction_rounded, size: 48, color: AppColors.gold),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.maintenanceTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(color: AppColors.onArena),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message.trim().isNotEmpty ? message : l10n.maintenanceDefaultMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
