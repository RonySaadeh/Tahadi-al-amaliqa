import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../home_turf_controller.dart';
import '../widgets/question_tile.dart';

/// Manage one home-turf category's question bank by hand-writing questions.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  Future<void> _showAddQuestionSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int correctIndex = 0;
    String difficulty = 'medium';

    await showModalBottomSheet(
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
          child: StatefulBuilder(
            builder: (sheetContext, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.homeTurfAddQuestion, style: Theme.of(sheetContext).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: questionController,
                        decoration: InputDecoration(labelText: l10n.homeTurfQuestionText),
                        validator: (v) => Validators.questionText(v) == null ? null : l10n.commonError,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RadioGroup<int>(
                        groupValue: correctIndex,
                        onChanged: (value) => setState(() => correctIndex = value!),
                        child: Column(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    Radio<int>(value: i),
                                    Expanded(
                                      child: TextFormField(
                                        controller: optionControllers[i],
                                        decoration: InputDecoration(labelText: l10n.homeTurfOption(i + 1)),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.commonError : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: difficulty,
                        decoration: InputDecoration(labelText: l10n.homeTurfDifficulty),
                        items: [
                          DropdownMenuItem(value: 'easy', child: Text(l10n.homeTurfDifficultyEasy)),
                          DropdownMenuItem(value: 'medium', child: Text(l10n.homeTurfDifficultyMedium)),
                          DropdownMenuItem(value: 'hard', child: Text(l10n.homeTurfDifficultyHard)),
                        ],
                        onChanged: (value) => setState(() => difficulty = value!),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await ref
                              .read(homeTurfControllerProvider.notifier)
                              .addQuestion(
                                categoryId: categoryId,
                                questionText: questionController.text.trim(),
                                options: optionControllers.map((c) => c.text.trim()).toList(),
                                correctAnswerIndex: correctIndex,
                                difficulty: difficulty,
                              );
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        },
                        child: Text(l10n.homeTurfSave),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final questionsAsync = ref.watch(categoryQuestionsProvider(categoryId));
    final controllerState = ref.watch(homeTurfControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTurfMyCategories)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuestionSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: controllerState.isLoading
          ? const Center(child: BrandedLoadingIndicator())
          : questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return Center(child: Text(l10n.homeTurfNoCategories));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: questions.length,
                  itemBuilder: (context, index) => QuestionTile(question: questions[index]),
                );
              },
              loading: () => const SkeletonList(),
              error: (_, _) => Center(child: Text(l10n.commonError)),
            ),
    );
  }
}
