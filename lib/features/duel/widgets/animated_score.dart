import 'package:flutter/material.dart';

/// A score number that counts up (or down) to [score] instead of jumping —
/// so a round's points read as something that just happened, landing on
/// the running total, rather than the total silently changing underneath
/// you between one frame and the next.
///
/// `TweenAnimationBuilder` does the actual work: when [score] changes
/// between builds, it smoothly retargets from whatever value it's
/// currently showing (even mid-flight) to the new one, rather than
/// restarting from scratch — exactly what a counter needs.
class AnimatedScore extends StatelessWidget {
  const AnimatedScore({super.key, required this.score, this.style});

  final int score;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: score),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) => Text(
        '$value',
        // Pinned LTR, same reasoning as every other score readout in the
        // duel screens — a digit run reorders under RTL bidi rules.
        textDirection: TextDirection.ltr,
        style: style,
      ),
    );
  }
}
