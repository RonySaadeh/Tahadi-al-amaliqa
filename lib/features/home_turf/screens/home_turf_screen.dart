import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../home_turf_controller.dart';
import '../widgets/category_card.dart';

/// "My categories" — create up to 3 home-turf categories, or open one to
/// manage its questions.
class HomeTurfScreen extends ConsumerWidget {
  const HomeTurfScreen({super.key});

  Future<void> _showCreateCategoryDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.homeTurfCreateCategory),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.homeTurfCategoryName),
                validator: (v) => Validators.categoryName(v) == null ? null : l10n.commonError,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: l10n.homeTurfCategoryDescription),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final categoryId = await ref
                  .read(homeTurfControllerProvider.notifier)
                  .createCategory(name: nameController.text.trim(), description: descriptionController.text.trim());
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (categoryId != null && context.mounted) {
                context.push(AppRoutes.homeTurfCategoryPath(categoryId));
              }
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
    final categoriesAsync = ref.watch(myCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTurfTitle)),
      body: categoriesAsync.when(
        data: (categories) {
          final canCreate = canCreateAnotherCategory(categories.length);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(l10n.homeTurfNoCategories, textAlign: TextAlign.center),
                )
              else
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CategoryCard(
                      category: category,
                      onTap: () => context.push(AppRoutes.homeTurfCategoryPath(category.id)),
                    ),
                  ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: canCreate ? () => _showCreateCategoryDialog(context, ref) : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(canCreate ? l10n.homeTurfCreateCategory : l10n.homeTurfMaxReached),
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
