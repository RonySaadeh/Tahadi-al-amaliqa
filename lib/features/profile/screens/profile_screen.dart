import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/level_calculator.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/rank_badge.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_controller.dart';
import '../../home/home_controller.dart';
import '../../home_turf/home_turf_controller.dart';
import '../profile_controller.dart';
import '../widgets/profile_settings_drawer.dart';
import '../widgets/stat_tile.dart';

/// The player's own page. Header is an arena field with the avatar
/// overlapping its lower edge — the single clearest example of the
/// "break the container" rule in the app, and the reason this screen no
/// longer reads as a settings list with a picture on top.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const double _avatarSize = 92;

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
            autofocus: true,
            validator: (v) => Validators.displayName(v) == null ? null : l10n.commonError,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref
                  .read(profileControllerProvider.notifier)
                  .updateDisplayName(controller.text.trim());
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
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final categoriesAsync = ref.watch(myCategoriesProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return userAsync.when(
      loading: () => const Scaffold(body: SkeletonList()),
      error: (_, _) => Scaffold(body: Center(child: Text(l10n.commonError))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());

        final level = LevelCalculator.calculate(wins: user.wins, losses: user.losses);
        final tier = RankTier.forElo(user.elo);
        final xpRemaining = level.xpSpanForLevel - level.xpIntoLevel;

        return Scaffold(
          drawer: ProfileSettingsDrawer(
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            tier: tier,
            locale: user.locale,
            onEditName: () => _showEditNameDialog(context, ref, user.displayName),
            onLocaleChanged: (value) => ref.read(profileControllerProvider.notifier).updateLocale(value),
            onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  ArenaPanel(
                    gradient: AppColors.arenaGradient,
                    slantHeight: 26,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      _avatarSize * 0.55,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.settings_rounded, color: AppColors.onArenaMuted),
                          tooltip: l10n.commonSettings,
                        ),
                      ),
                    ),
                  ),
                  // Deliberately hangs below the panel and over the page.
                  Positioned(
                    bottom: -_avatarSize * 0.42,
                    child: _LevelRingAvatar(
                      displayName: user.displayName,
                      photoUrl: user.photoUrl,
                      progress: level.progress,
                      size: _avatarSize,
                    ),
                  ),
                ],
              ),
              // Reclaims the space the avatar is hanging into.
              const SizedBox(height: _avatarSize * 0.42 + AppSpacing.sm),

              Center(child: Text(user.displayName, style: theme.textTheme.displaySmall)),
              Center(child: RankBadge(tier: tier)),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  '${l10n.profileLevel(level.level).toUpperCase()}  ·  ${l10n.profileXpToNext(xpRemaining).toUpperCase()}',
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  l10n.profileMemberSince(Formatters.joinDate(user.createdAt, locale: locale)),
                  style: theme.textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ResponsiveCenter(child: _StatsGrid(user: user, locale: locale, l10n: l10n)),
              ),

              const SizedBox(height: AppSpacing.lg),
              _Section(title: l10n.profileOwnedCategories),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                child: ResponsiveCenter(
                  child: categoriesAsync.when(
                    data: (categories) => categories.isEmpty
                        ? Text(l10n.homeTurfNoCategories, style: theme.textTheme.bodyMedium)
                        : Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: categories
                                .map(
                                  (c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceRaised,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                    ),
                                    child: Text(c.name, style: theme.textTheme.labelMedium),
                                  ),
                                )
                                .toList(),
                          ),
                    loading: () => const SkeletonListTile(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wins gets a double-width hero cell; everything else is a supporting
/// square. See [StatEmphasis].
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.user, required this.locale, required this.l10n});

  final UserModel user;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // `IntrinsicHeight` rather than a fixed `SizedBox` height: each row still
    // sizes its cells to the tallest one, but now grows with the content
    // (e.g. a larger accessibility text scale) instead of clipping it.
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: StatTile(
                  label: l10n.profileWins,
                  value: '${user.wins}',
                  accentColor: AppColors.success,
                  emphasis: StatEmphasis.hero,
                  icon: Icons.military_tech_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: l10n.profileCurrentStreak,
                  value: '${user.currentStreak}',
                  accentColor: AppColors.gold,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: l10n.profileEloRating,
                  value: Formatters.elo(user.elo, locale: locale),
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: l10n.profileLosses,
                  value: '${user.losses}',
                  accentColor: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: l10n.profileBestStreak,
                  value: '${user.bestStreak}',
                  accentColor: AppColors.playerOne,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The avatar with its XP progress drawn as a ring around it, so level
/// progress lives on the player's own portrait rather than in a separate bar
/// somewhere below it.
class _LevelRingAvatar extends StatelessWidget {
  const _LevelRingAvatar({
    required this.displayName,
    required this.photoUrl,
    required this.progress,
    required this.size,
  });

  final String displayName;
  final String? photoUrl;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = displayName.trim();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.arenaRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          Container(
            width: size - 14,
            height: size - 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.arenaDark,
              image: photoUrl != null
                  ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl != null
                ? null
                : Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
