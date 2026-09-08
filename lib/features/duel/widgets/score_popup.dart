import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// The "+120 pts" / "Incorrect" toast that flies up after a round resolves.
/// Purely cosmetic — driven entirely by the points the server already
/// computed and wrote to the round document.
class ScorePopup extends StatelessWidget {
  const ScorePopup({super.key, required this.pointsEarned, required this.wasCorrect});

  final int pointsEarned;
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    final color = wasCorrect ? AppColors.success : AppColors.error;
    final label = wasCorrect ? '+$pointsEarned' : '+0';

    return Text(
          label,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w900),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .moveY(begin: 12, end: -24, duration: 900.ms, curve: Curves.easeOut)
        .then()
        .fadeOut(duration: 300.ms);
  }
}
