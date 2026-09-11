import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's primary button: a solid slab sitting on a hard-edged colored
/// "edge" beneath it, which collapses when you press so the button visibly
/// travels into the page.
///
/// The depth is a zero-blur [BoxShadow], not an elevation — a blurred
/// Material shadow reads as *floating*, which is exactly the soft, generic
/// feel this design is trying to get away from. A hard edge reads as a
/// physical object with a side, and pressing it moves it. That single
/// behaviour is doing most of the work of making the app feel like a game
/// rather than a form.
class SlabButton extends StatefulWidget {
  const SlabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
    this.gradient,
    this.foreground = Colors.white,
    this.depthColor,
    this.fontSize = 15,
    this.expand = true,
    this.verticalPadding = AppSpacing.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Flat fill. Ignored when [gradient] is set.
  final Color? background;
  final Gradient? gradient;
  final Color foreground;

  /// The hard edge under the slab. Defaults to a darkened [background].
  final Color? depthColor;

  final double fontSize;
  final bool expand;
  final double verticalPadding;

  @override
  State<SlabButton> createState() => _SlabButtonState();
}

class _SlabButtonState extends State<SlabButton> {
  static const double _depth = 6;

  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  Color get _resolvedDepth {
    if (!_enabled) return AppColors.surfaceBorder;
    if (widget.depthColor != null) return widget.depthColor!;
    final base = widget.background ?? AppColors.primary;
    return Color.lerp(base, Colors.black, 0.32)!;
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = _enabled ? (widget.background ?? AppColors.primary) : AppColors.surfaceRaised;
    final labelColor = _enabled ? widget.foreground : AppColors.textDisabled;

    final slab = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      // Pressing travels the slab down by exactly the depth, so the edge
      // beneath it disappears rather than sliding out of alignment.
      transform: Matrix4.translationValues(0, _pressed ? _depth : 0, 0),
      padding: EdgeInsets.symmetric(
        vertical: widget.verticalPadding,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: widget.gradient == null || !_enabled ? fill : null,
        gradient: _enabled ? widget.gradient : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _pressed
            ? const []
            : [BoxShadow(color: _resolvedDepth, offset: const Offset(0, _depth), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: widget.fontSize + 5, color: labelColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: widget.fontSize,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      // Reserves the depth as real layout height so the travel on press
      // never shifts whatever sits below it.
      child: Padding(
        padding: const EdgeInsets.only(bottom: _depth),
        child: slab,
      ),
    );
  }
}
