import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../l10n/app_localizations.dart';

/// The Profile tab's settings surface — a standard slide-out drawer instead
/// of more controls crowded onto the profile page itself, so that page stays
/// about *this player* (stats, rank, owned categories) while account-level
/// actions (name, language, sign out) live in one consistent, familiar place.
/// Purely presentational: every action is a callback into whatever already
/// owns that state on `ProfileScreen`.
class ProfileSettingsDrawer extends StatelessWidget {
  const ProfileSettingsDrawer({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.tier,
    required this.locale,
    required this.onEditName,
    required this.onLocaleChanged,
    required this.onSignOut,
  });

  final String displayName;
  final String? photoUrl;
  final RankTier tier;
  final String locale;
  final VoidCallback onEditName;
  final ValueChanged<String> onLocaleChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = displayName.trim();

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: const BoxDecoration(gradient: AppColors.arenaGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tier.color.withValues(alpha: 0.18),
                      border: Border.all(color: tier.color, width: 2),
                      image: photoUrl != null
                          ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: photoUrl != null
                        ? null
                        : Text(
                            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(color: tier.color),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    name.isEmpty ? '?' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    l10n.commonSettings,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.profileEditName),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                onEditName();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.md),
                      Text(l10n.profileLanguage, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l10n.profileLanguageEnglish)),
                      ButtonSegment(value: 'ar', label: Text(l10n.profileLanguageArabic)),
                    ],
                    selected: {locale},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      final selected = selection.first;
                      if (selected != locale) onLocaleChanged(selected);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(l10n.authSignOut, style: const TextStyle(color: AppColors.error)),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                onSignOut();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
