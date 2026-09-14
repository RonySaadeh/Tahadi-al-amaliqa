import '../utils/rank_tier.dart';

/// Player avatar archetypes and frame tiers.
///
/// Archetypes are the base character illustrations under `assets/Avatar/`;
/// frames are the decorative border overlays under `assets/Frame/` that
/// signal rank/prestige. [ModularAvatarWidget] (in
/// `lib/core/widgets/modular_avatar.dart`) composites the two.
enum AvatarArchetype {
  strategist,
  berserker,
  trickster,
  champion,
  rookie,
  underdog,
}

enum AvatarFrame {
  bronze,
  silver,
  gold,
  titan,
}

extension AvatarArchetypeX on AvatarArchetype {
  String get assetPath {
    switch (this) {
      case AvatarArchetype.strategist:
        return 'assets/Avatar/avatar_strategist.png';
      case AvatarArchetype.berserker:
        return 'assets/Avatar/avatar_berserker.png';
      case AvatarArchetype.trickster:
        return 'assets/Avatar/avatar_trickster.png';
      case AvatarArchetype.champion:
        return 'assets/Avatar/avatar_champion.png';
      case AvatarArchetype.rookie:
        return 'assets/Avatar/avatar_rookie.png';
      case AvatarArchetype.underdog:
        return 'assets/Avatar/avatar_underdog.png';
    }
  }
}

extension AvatarFrameX on AvatarFrame {
  String get assetPath {
    switch (this) {
      case AvatarFrame.bronze:
        return 'assets/Frame/frame_bronze.png';
      case AvatarFrame.silver:
        return 'assets/Frame/frame_silver.png';
      case AvatarFrame.gold:
        return 'assets/Frame/frame_gold.png';
      case AvatarFrame.titan:
        return 'assets/Frame/frame_titan.png';
    }
  }
}

/// Maps a player's ELO-derived [RankTier] onto the closest [AvatarFrame] —
/// there are 5 rank tiers but only 4 frame assets, so the bottom two
/// (`noviceClay`, `bronzeSpartan`) share the bronze frame.
extension RankTierAvatarFrameX on RankTier {
  AvatarFrame get avatarFrame => switch (this) {
    RankTier.noviceClay || RankTier.bronzeSpartan => AvatarFrame.bronze,
    RankTier.silverGladiator => AvatarFrame.silver,
    RankTier.goldTitan => AvatarFrame.gold,
    RankTier.colossusMythic => AvatarFrame.titan,
  };
}
