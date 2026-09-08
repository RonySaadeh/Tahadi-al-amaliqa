import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum AnswerTileVisualState { neutral, selected, correct, incorrect, missed }

/// One multiple-choice option on the live duel screen.
///
/// [visualState] is purely derived from server data (the round's
/// `correctAnswerIndex` once resolved, plus the locally-selected index
/// before that) — this widget has no logic of its own about what's right.
class AnswerOptionTile extends StatelessWidget {
  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.visualState,
    required this.onTap,
  });

  final String label;
  final AnswerTileVisualState visualState;
  final VoidCallback? onTap;

  Color get _borderColor => switch (visualState) {
    AnswerTileVisualState.neutral => AppColors.surfaceBorder,
    AnswerTileVisualState.selected => AppColors.primary,
    AnswerTileVisualState.correct => AppColors.success,
    AnswerTileVisualState.incorrect => AppColors.error,
    AnswerTileVisualState.missed => AppColors.surfaceBorder,
  };

  Color get _fillColor => switch (visualState) {
    AnswerTileVisualState.neutral => AppColors.surfaceRaised,
    AnswerTileVisualState.selected => AppColors.primary.withValues(alpha: 0.18),
    AnswerTileVisualState.correct => AppColors.success.withValues(alpha: 0.18),
    AnswerTileVisualState.incorrect => AppColors.error.withValues(alpha: 0.18),
    AnswerTileVisualState.missed => AppColors.surfaceRaised,
  };

  IconData? get _icon => switch (visualState) {
    AnswerTileVisualState.correct => Icons.check_circle_rounded,
    AnswerTileVisualState.incorrect => Icons.cancel_rounded,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary)),
          ),
          if (_icon != null) Icon(_icon, color: _borderColor),
        ],
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: content,
      ),
    );

    if (visualState == AnswerTileVisualState.incorrect) {
      return tappable.animate().shake(duration: 350.ms);
    }
    if (visualState == AnswerTileVisualState.correct) {
      return tappable.animate().scale(duration: 250.ms, begin: const Offset(1, 1), end: const Offset(1.03, 1.03));
    }
    return tappable;
  }
}
