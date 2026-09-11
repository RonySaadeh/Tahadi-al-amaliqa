import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum AnswerTileVisualState { neutral, selected, correct, incorrect, missed }

/// One multiple-choice option in the duel arena.
///
/// Built as a slab with a hard bottom edge that collapses on press (the same
/// physical language as `SlabButton`) rather than a bordered list tile — an
/// answer should feel like something you *hit*, not something you select
/// from a menu. Each option carries an A/B/C/D index chip so players can
/// talk about answers out loud and so the eye has a fixed left anchor down
/// the stack.
///
/// [visualState] is purely derived from server data (the round's
/// `correctAnswerIndex` once resolved, plus the locally-selected index
/// before that) — this widget has no logic of its own about what's right.
class AnswerOptionTile extends StatefulWidget {
  const AnswerOptionTile({
    super.key,
    required this.label,
    required this.indexLabel,
    required this.visualState,
    required this.onTap,
  });

  final String label;

  /// "A", "B", "C", "D" — position, not correctness.
  final String indexLabel;
  final AnswerTileVisualState visualState;
  final VoidCallback? onTap;

  @override
  State<AnswerOptionTile> createState() => _AnswerOptionTileState();
}

class _AnswerOptionTileState extends State<AnswerOptionTile> {
  static const double _depth = 5;

  bool _pressed = false;

  Color get _fill => switch (widget.visualState) {
    AnswerTileVisualState.neutral => AppColors.arenaRaised,
    AnswerTileVisualState.selected => AppColors.primary,
    AnswerTileVisualState.correct => AppColors.success,
    AnswerTileVisualState.incorrect => AppColors.error,
    // A correct answer the player didn't pick: outlined, not filled, so it
    // reads as information rather than as their result.
    AnswerTileVisualState.missed => AppColors.arenaRaised,
  };

  Color get _content => switch (widget.visualState) {
    AnswerTileVisualState.correct => AppColors.arenaDark,
    AnswerTileVisualState.incorrect => Colors.white,
    AnswerTileVisualState.selected => Colors.white,
    _ => AppColors.onArena,
  };

  Border? get _border => widget.visualState == AnswerTileVisualState.missed
      ? Border.all(color: AppColors.success, width: 2)
      : null;

  IconData? get _icon => switch (widget.visualState) {
    AnswerTileVisualState.correct => Icons.check_circle_rounded,
    AnswerTileVisualState.incorrect => Icons.cancel_rounded,
    AnswerTileVisualState.missed => Icons.subdirectory_arrow_left_rounded,
    _ => null,
  };

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final depthColor = Color.lerp(_fill, Colors.black, 0.45)!;

    final slab = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? _depth : 0, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: _fill,
        border: _border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _pressed
            ? const []
            : [BoxShadow(color: depthColor, offset: const Offset(0, _depth), blurRadius: 0)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              widget.indexLabel,
              // Pinned LTR: A/B/C/D are positional labels, and under RTL the
              // trailing period would jump to the wrong side of the letter.
              textDirection: TextDirection.ltr,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 15,
                color: _content.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _content,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          if (_icon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(_icon, color: _content, size: 20),
          ],
        ],
      ),
    );

    final tappable = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _depth),
        child: slab,
      ),
    );

    return switch (widget.visualState) {
      AnswerTileVisualState.incorrect => tappable.animate().shake(duration: 350.ms, hz: 5),
      // A pop to land the hit, then a double-blink so "correct" reads as an
      // event happening, not just a color that was always going to be here.
      AnswerTileVisualState.correct => tappable
          .animate()
          .scaleXY(duration: 220.ms, begin: 1, end: 1.03, curve: Curves.easeOut)
          .then()
          .scaleXY(duration: 160.ms, begin: 1, end: 1 / 1.03)
          .then(delay: 80.ms)
          .fadeOut(duration: 110.ms, curve: Curves.easeInOut)
          .then()
          .fadeIn(duration: 110.ms)
          .then()
          .fadeOut(duration: 110.ms)
          .then()
          .fadeIn(duration: 110.ms),
      _ => tappable,
    };
  }
}
