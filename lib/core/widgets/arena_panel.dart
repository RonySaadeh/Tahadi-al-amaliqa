import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A full-bleed dark "arena" region with a diagonal bottom edge.
///
/// This is the structural device the whole redesign hangs on. Instead of
/// floating a white card on a light page — the pattern that made every
/// screen look identical — a hero region is cut *out* of the page as a dark
/// field, and the angled edge stops it from reading as just another
/// rectangle. Content that should feel like it belongs to both zones (an
/// avatar, a rating, a CTA) is then deliberately overlapped across that
/// edge by the screen using a negative margin.
///
/// [slantHeight] is how far the edge falls from one side to the other, in
/// logical pixels. It intentionally does not mirror under RTL: the slant is
/// a graphic constant of the brand, not a reading-order cue.
class ArenaPanel extends StatelessWidget {
  const ArenaPanel({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.slantHeight = 26,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double slantHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DiagonalBottomClipper(slantHeight: slantHeight),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? AppColors.arenaDark) : null,
          gradient: gradient,
        ),
        // The clip eats into the bottom-right corner, so anything sitting at
        // the bottom of the panel needs the slant added back as padding or
        // it gets sliced. The status bar/notch height is added to the top
        // for the same kind of reason: every caller uses this panel as a
        // full-bleed screen-top hero with no `AppBar`/`SafeArea` of its own
        // (that's the whole point — see the class doc), so without this the
        // panel's own content (a title, an avatar row, a settings icon)
        // would render right up against the device's status bar instead of
        // just the background gradient bleeding under it.
        padding: padding.add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: slantHeight)),
        child: child,
      ),
    );
  }
}

class _DiagonalBottomClipper extends CustomClipper<Path> {
  const _DiagonalBottomClipper({required this.slantHeight});

  final double slantHeight;

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height - slantHeight)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalBottomClipper oldClipper) => oldClipper.slantHeight != slantHeight;
}

/// The duel arena's clash field: two identity-colored halves meeting at a
/// hard diagonal instead of a horizontal rule. Painted behind the live duel
/// so the two players visibly own opposing territory.
class ClashBackdrop extends StatelessWidget {
  const ClashBackdrop({
    super.key,
    this.topColor = AppColors.playerOne,
    this.bottomColor = AppColors.playerTwo,
    this.opacity = 0.16,
  });

  final Color topColor;
  final Color bottomColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ClashPainter(
          topColor: topColor.withValues(alpha: opacity),
          bottomColor: bottomColor.withValues(alpha: opacity),
          seam: AppColors.clashYellow.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ClashPainter extends CustomPainter {
  const _ClashPainter({required this.topColor, required this.bottomColor, required this.seam});

  final Color topColor;
  final Color bottomColor;
  final Color seam;

  @override
  void paint(Canvas canvas, Size size) {
    // The seam runs from 46% on the left to 38% on the right — off-level on
    // purpose. A horizontal split would read as a layout boundary; a tilted
    // one reads as two forces meeting.
    final leftY = size.height * 0.46;
    final rightY = size.height * 0.38;

    final top = Path()
      ..lineTo(0, leftY)
      ..lineTo(size.width, rightY)
      ..lineTo(size.width, 0)
      ..close();

    final bottom = Path()
      ..moveTo(0, leftY)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, rightY)
      ..close();

    canvas.drawPath(top, Paint()..color = topColor);
    canvas.drawPath(bottom, Paint()..color = bottomColor);
    canvas.drawLine(
      Offset(0, leftY),
      Offset(size.width, rightY),
      Paint()
        ..color = seam
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ClashPainter oldDelegate) =>
      oldDelegate.topColor != topColor || oldDelegate.bottomColor != bottomColor;
}
