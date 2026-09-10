import 'package:flutter/material.dart';

/// Soft shadows, used instead of hard 1px borders on card-like surfaces —
/// the single biggest lever for moving this app from "flat and bordered" to
/// "modern and lifted". [glow] additionally gives brand-colored hero
/// surfaces (buttons, stat cards) a soft tinted halo instead of a plain
/// grey one, which reads as more playful/premium than a neutral shadow.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x1F231E36), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x14231E36), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.35, double blur = 24, Offset offset = const Offset(0, 10)}) {
    return [BoxShadow(color: color.withValues(alpha: opacity), blurRadius: blur, offset: offset)];
  }
}
