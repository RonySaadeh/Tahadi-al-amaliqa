import 'package:flutter/widgets.dart';

/// Window-size thresholds, matching Material's own compact/medium/expanded
/// classes. This app only ships to phones and web (see `.metadata`), so in
/// practice "medium/expanded" means a tablet, a foldable unfolded, or a
/// desktop browser window rather than a dedicated desktop build.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Below this, the device is treated as a phone: single column, bottom
  /// nav, content free to use the full width.
  static const double compact = 600;

  /// At/above this, a `NavigationRail` gets its wider "extended" treatment
  /// (label beside the icon) instead of the compact icon-with-label-below
  /// form.
  static const double expanded = 840;

  /// The width a single reading column is capped to on anything wider than
  /// a phone, so lists/forms/stats stay a legible column instead of
  /// stretching edge-to-edge — matches the width `WelcomeScreen` already
  /// settled on for its sign-in form. Full-bleed elements (arena headers,
  /// duel backgrounds) deliberately ignore this and stay edge-to-edge.
  static const double contentMaxWidth = 420;
}

extension ResponsiveContext on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompactWidth => _screenWidth < AppBreakpoints.compact;
  bool get isExpandedWidth => _screenWidth >= AppBreakpoints.expanded;
}
