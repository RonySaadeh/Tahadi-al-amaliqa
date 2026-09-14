import 'package:flutter/material.dart';

import '../theme/mascot_assets.dart';

/// Displays the branded mascot illustration matching a given [MascotMood].
///
/// This stays a plain [StatelessWidget] with no dependency on any state
/// management approach — callers translate their own state (duel result,
/// question-loading flag, etc.) into a [MascotMood] and pass it in.
class MascotDisplay extends StatelessWidget {
  const MascotDisplay({
    super.key,
    required this.mood,
    this.size,
  });

  final MascotMood mood;

  /// Overrides the default size (384 for [MascotMood.idle]'s hero art,
  /// 256 for every other mood).
  final double? size;

  String get _asset {
    switch (mood) {
      case MascotMood.victory:
        return MascotAssets.win;
      case MascotMood.thinking:
        return MascotAssets.think;
      case MascotMood.defeat:
        return MascotAssets.lose;
      case MascotMood.idle:
        return MascotAssets.hero;
    }
  }

  double get _defaultSize => mood == MascotMood.idle ? 384.0 : 256.0;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? _defaultSize;
    return Image.asset(
      _asset,
      width: resolvedSize,
      height: resolvedSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
