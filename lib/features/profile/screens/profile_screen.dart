import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_controller.dart';
import '../../home/home_controller.dart';
import '../../home_turf/home_turf_controller.dart';
import '../profile_controller.dart';
import '../widgets/stat_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileEditName),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            validator: (v) => Validators.displayName(v) == null ? null : l10n.commonError,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(profileControllerProvider.notifier).updateDisplayName(controller.text.trim());
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProvider);
    final categoriesAsync = ref.watch(myCategoriesProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.authSignOut,
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceRaised,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null
                      ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '?', style: const TextStyle(fontSize: 32))
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showEditNameDialog(context, ref, user.displayName),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              Center(
                child: Text(
                  l10n.profileMemberSince(Formatters.joinDate(user.createdAt, locale: locale)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.profileStats, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.6,
                children: [
                  StatTile(label: l10n.profileEloRating, value: Formatters.elo(user.elo, locale: locale)),
                  StatTile(label: l10n.profileWins, value: '${user.wins}', accentColor: AppColors.success),
                  StatTile(label: l10n.profileLosses, value: '${user.losses}', accentColor: AppColors.error),
                  StatTile(label: l10n.profileCurrentStreak, value: '${user.currentStreak}', accentColor: AppColors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.profileLanguage, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'ar', label: Text(l10n.profileLanguageArabic)),
                  ButtonSegment(value: 'en', label: Text(l10n.profileLanguageEnglish)),
                ],
                selected: {user.locale},
                onSelectionChanged: (selection) {
                  final selected = selection.first;
                  if (selected != user.locale) {
                    ref.read(profileControllerProvider.notifier).updateLocale(selected);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.profileOwnedCategories, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              categoriesAsync.when(
                data: (categories) => Wrap(
                  spacing: AppSpacing.sm,
                  children: categories.map((c) => Chip(label: Text(c.name))).toList(),
                ),
                loading: () => const SkeletonListTile(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const SkeletonList(),
        error: (_, _) => Center(child: Text(l10n.commonError)),
      ),
    );
  }
}
