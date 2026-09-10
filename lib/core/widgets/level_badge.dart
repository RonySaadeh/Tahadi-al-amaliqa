import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/level_calculator.dart';

/// The small numbered circle that overlays the bottom-end corner of an
/// avatar — see [PlayerAvatar]. Color is purely decorative, grouped by
/// [LevelTier].
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, required this.tier, this.size = 22});

  final int level;
  final LevelTier tier;
  final double size;

  Color get _color => switch (tier) {
    LevelTier.bronze => const Color(0xFFCD7F32),
    LevelTier.silver => const Color(0xFFB4BCD0),
    LevelTier.gold => AppColors.gold,
    LevelTier.diamond => AppColors.playerOne,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: Text(
        '$level',
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w900, color: AppColors.onBrand, height: 1),
      ),
    );
  }
}

/// A profile avatar (photo or initial) with its owner's [LevelBadge]
/// pinned to the bottom-end corner. The one place in the app that should
/// ever render a player avatar — every screen showing one (profile, duel
/// header, results) goes through this so the level badge is never
/// forgotten on one screen and present on another.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    required this.wins,
    required this.losses,
    this.radius = 44,
  });

  final String displayName;
  final String? photoUrl;
  final int wins;
  final int losses;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final playerLevel = LevelCalculator.calculate(wins: wins, losses: losses);
    final badgeSize = radius * 0.55;

    return SizedBox(
      width: radius * 2 + badgeSize / 2,
      height: radius * 2 + badgeSize / 2,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.surfaceRaised,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: radius * 0.7),
                  )
                : null,
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: LevelBadge(level: playerLevel.level, tier: playerLevel.tier, size: badgeSize),
          ),
        ],
      ),
    );
  }
}
