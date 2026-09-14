import 'package:flutter/material.dart';

import '../theme/avatar_system.dart';

/// Composites an [AvatarArchetype] illustration with an [AvatarFrame]
/// overlay in a [Stack].
///
/// Both layers are pre-centered, symmetrical square art at the same
/// resolution, so no manual alignment or RTL mirroring is needed.
class ModularAvatarWidget extends StatelessWidget {
  const ModularAvatarWidget({
    super.key,
    required this.archetype,
    required this.frame,
    this.size = 64.0,
  });

  final AvatarArchetype archetype;
  final AvatarFrame frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            archetype.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          Image.asset(
            frame.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}
