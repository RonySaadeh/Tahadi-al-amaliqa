import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/question_model.dart';

class QuestionTile extends StatelessWidget {
  const QuestionTile({super.key, required this.question});

  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.questionText, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < question.options.length; i++)
                  Chip(
                    label: Text(question.options[i]),
                    backgroundColor: i == question.correctAnswerIndex
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.surfaceRaised,
                    side: BorderSide(
                      color: i == question.correctAnswerIndex ? AppColors.success : AppColors.surfaceBorder,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
