import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_controller.dart';

/// A non-blocking nudge shown on Home for email/password accounts that
/// haven't clicked their verification link yet — see
/// `EmailVerificationController`. Never shown for Google/Apple sign-ins,
/// and never blocks any app feature; it just sits here until dismissed by
/// actually verifying.
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsVerification = ref.watch(needsEmailVerificationProvider);
    if (!needsVerification) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.authVerifyEmailTitle, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.authVerifyEmailMessage, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await ref.read(needsEmailVerificationProvider.notifier).resend();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.authVerificationSent)));
                  }
                },
                child: Text(l10n.authResendVerification),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  await ref.read(needsEmailVerificationProvider.notifier).refresh();
                  if (context.mounted && ref.read(needsEmailVerificationProvider)) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.authStillNotVerified)));
                  }
                },
                child: Text(l10n.authIveVerified),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
