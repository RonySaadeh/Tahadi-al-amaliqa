import 'package:flutter/material.dart';

/// The full color palette for the app. Light-first, playful "fun trivia
/// game" look — bright saturated brand colors on soft off-white surfaces,
/// closer to Duolingo/Kahoot than a dense dark utility app.
///
/// If you only ever change one file to re-skin the app, it's this one —
/// every screen reads colors through these named tokens rather than literal
/// hex values, so retuning a value here cascades everywhere it's used.
class AppColors {
  const AppColors._();

  // --- Base surfaces (light, warm, friendly) ---
  static const Color background = Color(0xFFF8F6FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFEFEBFA);
  static const Color surfaceBorder = Color(0xFFEDE9F9);

  // --- Brand ---
  /// Vivid violet — primary brand color, used for CTAs and highlights.
  static const Color primary = Color(0xFF6C4CFF);
  static const Color primaryDim = Color(0xFF5136CC);

  /// Champion gold — used for ELO/rank, trophies, streaks, celebration.
  static const Color gold = Color(0xFFFFB020);
  static const Color goldDim = Color(0xFFE0921A);

  // --- Duel "vs" identity colors (player 1 vs player 2) ---
  static const Color playerOne = Color(0xFF17B6E0); // sky cyan
  static const Color playerTwo = Color(0xFFFF5C9E); // magenta pink

  // --- Semantic feedback ---
  static const Color success = Color(0xFF3DCB6C);
  static const Color error = Color(0xFFFF4D5E);
  static const Color warning = Color(0xFFFFA726);

  // --- Text ---
  static const Color textPrimary = Color(0xFF231E36);
  static const Color textSecondary = Color(0xFF827D99);
  static const Color textDisabled = Color(0xFFC3BFD6);

  /// Text/icon color to use on top of [gold] or another bright/light brand
  /// surface (trophy circles, gold gradients, tier badges) — a dark ink
  /// color, since those surfaces are too light for white text to read well.
  /// Buttons on [primary] use plain white instead (see `AppTheme`) — violet
  /// is dark/saturated enough for that, gold isn't.
  static const Color onBrand = Color(0xFF241E38);

  // --- Gradients used for hero/CTA surfaces ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFF), Color(0xFF5B3DF0)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC94D), Color(0xFFFFA020)],
  );

  static const LinearGradient vsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [playerOne, playerTwo],
  );
}
