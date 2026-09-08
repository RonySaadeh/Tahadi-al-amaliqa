import 'package:flutter/material.dart';

/// The full color palette for the app. Dark-first "arena" theme — chosen to
/// feel like a live competitive game (closer to a sports-betting/esports app
/// than a form-based utility app), not default Material colors.
///
/// If you only ever change one file to re-skin the app, it's this one.
class AppColors {
  const AppColors._();

  // --- Base surfaces (dark, layered) ---
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141A2E);
  static const Color surfaceRaised = Color(0xFF1D2440);
  static const Color surfaceBorder = Color(0xFF2A3352);

  // --- Brand ---
  /// Electric violet — primary brand color, used for CTAs and highlights.
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryDim = Color(0xFF6D28D9);

  /// Champion gold — used for ELO/rank, trophies, streaks, celebration.
  static const Color gold = Color(0xFFFBBF24);
  static const Color goldDim = Color(0xFFB45309);

  // --- Duel "vs" identity colors (player 1 vs player 2) ---
  static const Color playerOne = Color(0xFF22D3EE); // cyan
  static const Color playerTwo = Color(0xFFF472B6); // magenta

  // --- Semantic feedback ---
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // --- Text ---
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFA0A8C3);
  static const Color textDisabled = Color(0xFF5C6488);

  /// Text color to use on top of [primary] or [gold] fills.
  static const Color onBrand = Color(0xFF0A0E1A);

  // --- Gradients used for hero/CTA surfaces ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient vsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [playerOne, playerTwo],
  );
}
