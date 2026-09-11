import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/home_controller.dart';
import '../duel_controller.dart';
import 'category_catalog.dart';

/// Picks a category, then sends a duel challenge to [toUserId] through the
/// same `sendChallenge` call every other challenge in the app uses — the
/// one thing a "Challenge" button on the friends list or another player's
/// profile needs that isn't already fixed (the opponent is; the category
/// isn't). Shared so both call sites stay in sync rather than growing two
/// slightly different pickers.
Future<void> showChallengeCategorySheet(BuildContext context, {required String toUserId}) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          child: Consumer(
            builder: (context, ref, _) {
              final groupsAsync = ref.watch(categoryGroupsProvider);
              final categoriesAsync = ref.watch(categoriesProvider);
              final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
              final locale = ref.watch(currentUserProvider).value?.locale;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.duelSelectCategory, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: SingleChildScrollView(
                      child: groupsAsync.when(
                        data: (groups) => categoriesAsync.when(
                          data: (categories) => CategoryCatalog(
                            groups: groups,
                            categories: categories,
                            selectedCategoryId: selectedCategoryId,
                            locale: locale,
                            onSelect: (category) => ref
                                .read(selectedCategoryIdProvider.notifier)
                                .set(category.id == selectedCategoryId ? null : category.id),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => Text(l10n.commonError),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => Text(l10n.commonError),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SlabButton(
                    label: l10n.friendsChallenge,
                    onPressed: selectedCategoryId == null
                        ? null
                        : () async {
                            await ref
                                .read(duelControllerProvider.notifier)
                                .sendChallenge(toUserId: toUserId, categoryId: selectedCategoryId);
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          },
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
