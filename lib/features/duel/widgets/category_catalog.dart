import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/category_icons.dart';
import '../../../data/models/category_group_model.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';

/// Browsable category catalog for the duel lobby: one section per
/// [CategoryGroupModel] (Sports, History, ...), each showing its categories
/// as a horizontally-scrollable row of chips rather than a single long
/// vertical list — with ~60 seeded categories across ~10 groups, this reads
/// like a catalog you skim instead of a picklist you search through.
/// Home-turf categories (`groupId: null`) get their own trailing section.
class CategoryCatalog extends StatelessWidget {
  const CategoryCatalog({
    super.key,
    required this.groups,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.locale,
  });

  final List<CategoryGroupModel> groups;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<CategoryModel> onSelect;

  /// The viewer's `users/{uid}.locale` ('ar'/'en') — picks which of each
  /// category/group's two names to display. See
  /// `CategoryModel.displayName`.
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final byGroup = <String, List<CategoryModel>>{};
    final ungrouped = <CategoryModel>[];
    for (final category in categories) {
      if (category.groupId == null) {
        ungrouped.add(category);
      } else {
        (byGroup[category.groupId!] ??= []).add(category);
      }
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => a.displayName(locale).compareTo(b.displayName(locale)));
    }
    ungrouped.sort((a, b) => a.displayName(locale).compareTo(b.displayName(locale)));

    final sortedGroups = [...groups]..sort((a, b) => a.order.compareTo(b.order));
    final visibleGroups = sortedGroups.where((g) => (byGroup[g.id]?.isNotEmpty ?? false)).toList();

    if (visibleGroups.isEmpty && ungrouped.isEmpty) {
      return Text(l10n.commonError);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in visibleGroups)
          _CatalogSection(
            icon: categoryGroupIcon(group.iconKey),
            title: group.displayName(locale),
            categories: byGroup[group.id]!,
            selectedCategoryId: selectedCategoryId,
            onSelect: onSelect,
            locale: locale,
          ),
        if (ungrouped.isNotEmpty)
          _CatalogSection(
            icon: Icons.flag_rounded,
            title: l10n.duelHomeTurfCategoriesSection,
            categories: ungrouped,
            selectedCategoryId: selectedCategoryId,
            onSelect: onSelect,
            locale: locale,
          ),
      ],
    );
  }
}

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.icon,
    required this.title,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.locale,
  });

  final IconData icon;
  final String title;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<CategoryModel> onSelect;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: AppSpacing.md),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryChip(
                  category: category,
                  icon: icon,
                  selected: category.id == selectedCategoryId,
                  onTap: () => onSelect(category),
                  locale: locale,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.locale,
  });

  final CategoryModel category;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surface,
          border: selected ? null : Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.displayName(locale),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: selected ? Colors.white : null),
            ),
          ],
        ),
      ),
    );
  }
}
