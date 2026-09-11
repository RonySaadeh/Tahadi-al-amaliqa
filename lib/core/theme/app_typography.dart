import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's two-voice type system.
///
/// **Titan One** is the display voice — the logo, scores, ratings, countdowns
/// and result verdicts. It is a single-weight slab face with enormous
/// presence, and it is what makes a number feel like an announcement rather
/// than a data point. Never set `fontWeight` on it; it only ships one.
///
/// **Outfit** is the working voice — questions, labels, body copy, buttons.
///
/// Neither face covers Arabic, so in Arabic the whole scale collapses onto
/// **Tajawal**, which has the weight range (up to w900) to carry both roles.
/// That's why every entry point here takes an `isArabic` flag rather than
/// exposing bare `TextStyle` constants: the theme is rebuilt when the
/// player switches language (see `main.dart`).
class AppTypography {
  const AppTypography._();

  static const String _displayFamily = 'Titan One';
  static const String _bodyFamily = 'Outfit';
  static const String _arabicFamily = 'Tajawal';

  /// The display face at an arbitrary size. Use for anything that should
  /// read as a headline or a number-as-spectacle.
  static TextStyle display({
    required bool isArabic,
    required double fontSize,
    Color color = AppColors.textPrimary,
    double height = 1,
    double letterSpacing = 0.5,
  }) {
    if (isArabic) {
      return TextStyle(
        fontFamily: _arabicFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        height: height,
      );
    }
    return TextStyle(
      fontFamily: _displayFamily,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// The working face. [weight] is honored in both scripts.
  static TextStyle body({
    required bool isArabic,
    required double fontSize,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double height = 1.35,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: isArabic ? _arabicFamily : _bodyFamily,
      fontSize: fontSize,
      fontWeight: weight,
      // Outfit is a variable font, and Flutter selects the file by family
      // but does not drive the `wght` axis from `fontWeight` — without this
      // every weight would render at the font's 400 default (or get faked
      // by synthetic bolding). Tajawal ships real static cuts, so it needs
      // nothing here.
      fontVariations: isArabic ? null : [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// The tiny all-caps tracking-wide label that sits above almost every
  /// number in this design — "CURRENT RATING", "FINAL SCORE", "ROUND 3 OF 5".
  /// Its job is to be small enough that the number above/below it looks huge
  /// by comparison; that contrast is the whole visual trick.
  static TextStyle overline({
    required bool isArabic,
    Color color = AppColors.textSecondary,
    double fontSize = 10,
  }) {
    return body(
      isArabic: isArabic,
      fontSize: fontSize,
      weight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: 1.4,
    );
  }

  static TextTheme textTheme({required bool isArabic}) {
    return TextTheme(
      // Display slots are the Titan One voice.
      displayLarge: display(isArabic: isArabic, fontSize: 44, height: 1.05),
      displayMedium: display(isArabic: isArabic, fontSize: 34, height: 1.1),
      displaySmall: display(isArabic: isArabic, fontSize: 26, height: 1.15),

      // Headlines are the working face at its heaviest — question text and
      // section heads need to hold a lot of characters, which Titan One
      // handles badly at length.
      headlineLarge: body(isArabic: isArabic, fontSize: 26, weight: FontWeight.w800, height: 1.2),
      headlineMedium: body(isArabic: isArabic, fontSize: 21, weight: FontWeight.w800, height: 1.3),
      headlineSmall: body(isArabic: isArabic, fontSize: 18, weight: FontWeight.w700, height: 1.3),

      titleLarge: body(isArabic: isArabic, fontSize: 17, weight: FontWeight.w700),
      titleMedium: body(isArabic: isArabic, fontSize: 15, weight: FontWeight.w600),
      titleSmall: body(isArabic: isArabic, fontSize: 13, weight: FontWeight.w600),

      bodyLarge: body(isArabic: isArabic, fontSize: 16, weight: FontWeight.w400, height: 1.45),
      bodyMedium: body(
        isArabic: isArabic,
        fontSize: 14,
        weight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
      bodySmall: body(
        isArabic: isArabic,
        fontSize: 12,
        weight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      ),

      labelLarge: body(isArabic: isArabic, fontSize: 14, weight: FontWeight.w800, letterSpacing: 0.3),
      labelMedium: body(isArabic: isArabic, fontSize: 12, weight: FontWeight.w700, letterSpacing: 0.4),
      labelSmall: overline(isArabic: isArabic, fontSize: 11),
    );
  }
}
