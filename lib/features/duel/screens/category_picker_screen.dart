import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/category_group_model.dart';
import '../../../data/models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../home_turf/widgets/category_card.dart';
import '../duel_controller.dart';

/// A full-screen, searchable, grouped category picker — pushed (not routed
/// via go_router, since it's a transient "pick one and pop back" flow) from
/// the challenge-a-friend sheet in `duel_lobby_screen.dart`.
///
/// With ~60 seeded categories (see
/// `functions/src/seed/categoryTaxonomy.ts`) a flat dropdown stops being
/// usable — this groups them under the same section headers the taxonomy
/// data defines (Sports, Movies & TV, ...) so a player can jump straight to
/// what they care about instead of scanning one long list. Returns the
/// chosen category's id via `Navigator.pop`.
class CategoryPickerScreen extends ConsumerStatefulWidget {
  const CategoryPickerScreen({super.key});

  @override
  ConsumerState<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends ConsumerState<CategoryPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(categoryGroupsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.duelSelectCategory),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: l10n.duelSearchCategory,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
      ),
      body: groupsAsync.when(
        loading: () => const SkeletonList(),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (groups) => categoriesAsync.when(
          loading: () => const SkeletonList(),
          error: (_, _) => Center(child: Text(l10n.commonError)),
          data: (categories) => _buildList(context, l10n, groups, categories),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    List<CategoryGroupModel> groups,
    List<CategoryModel> categories,
  ) {
    final query = _query.toLowerCase();
    bool matches(CategoryModel c) => query.isEmpty || c.name.toLowerCase().contains(query);

    final byGroup = <String, List<CategoryModel>>{};
    final ungrouped = <CategoryModel>[];
    for (final category in categories) {
      if (!matches(category)) continue;
      if (category.groupId == null) {
        ungrouped.add(category);
      } else {
        (byGroup[category.groupId!] ??= []).add(category);
      }
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    ungrouped.sort((a, b) => a.name.compareTo(b.name));

    final sortedGroups = [...groups]..sort((a, b) => a.order.compareTo(b.order));
    final visibleGroups = sortedGroups.where((g) => (byGroup[g.id]?.isNotEmpty ?? false)).toList();

    if (visibleGroups.isEmpty && ungrouped.isEmpty) {
      return Center(child: Text(l10n.duelNoCategoriesFound));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        for (final group in visibleGroups) ...[
          _SectionHeader(icon: categoryGroupIcon(group.iconKey), title: group.name),
          const SizedBox(height: AppSpacing.sm),
          for (final category in byGroup[group.id]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CategoryCard(category: category, onTap: () => Navigator.of(context).pop(category.id)),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (ungrouped.isNotEmpty) ...[
          _SectionHeader(icon: Icons.flag_rounded, title: l10n.duelHomeTurfCategoriesSection),
          const SizedBox(height: AppSpacing.sm),
          for (final category in ungrouped)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CategoryCard(category: category, onTap: () => Navigator.of(context).pop(category.id)),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
