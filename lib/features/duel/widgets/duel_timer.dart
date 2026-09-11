import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// The countdown ring at the center of the arena HUD.
///
/// Sized and placed to be one of the two loudest things on the screen (the
/// other being the question) — a round timer that reads as a small status
/// number is a wasted source of tension. Under 5 seconds it flips to red and
/// starts pulsing.
///
/// Ticks locally once a second from [roundStartedAt]; the authority on
/// "time's up" is still the server (see
/// `functions/src/scoring/expireStaleRounds.ts`), this is just the visible
/// clock.
class DuelTimer extends StatefulWidget {
  const DuelTimer({
    super.key,
    required this.roundStartedAt,
    this.timeLimitSeconds = AppConstants.roundTimeLimitSeconds,
    this.onTimeUp,
    this.diameter = 76,
  });

  final DateTime roundStartedAt;
  final int timeLimitSeconds;
  final VoidCallback? onTimeUp;
  final double diameter;

  @override
  State<DuelTimer> createState() => _DuelTimerState();
}

class _DuelTimerState extends State<DuelTimer> {
  Timer? _ticker;
  late Duration _remaining;
  bool _firedTimeUp = false;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Duration _computeRemaining() {
    final elapsed = DateTime.now().difference(widget.roundStartedAt);
    final total = Duration(seconds: widget.timeLimitSeconds);
    // `roundStartedAt` can legitimately be in the future — round 1's is
    // stamped a few seconds ahead server-side so its answer window starts
    // once the VS intro screen ends, not before (see `createDuel.ts`).
    // Without this clamp a future `roundStartedAt` makes `elapsed` negative
    // and this would count UP past `total` instead of just holding there.
    if (elapsed.isNegative) return total;
    final remaining = total - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _tick() {
    final remaining = _computeRemaining();
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero && !_firedTimeUp) {
      _firedTimeUp = true;
      widget.onTimeUp?.call();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_remaining.inMilliseconds / (widget.timeLimitSeconds * 1000)).clamp(0.0, 1.0);
    // Rounded up, not truncated: with `inSeconds` a 10-second round renders
    // "10" only for the instant before the first frame and then parks on "0"
    // for a full second at the end. Ceiling gives every number an actual
    // second on screen, which is what a countdown is for.
    final secondsLeft = (_remaining.inMilliseconds / 1000).ceil();
    final isUrgent = secondsLeft <= 5;
    final accent = isUrgent ? AppColors.error : AppColors.gold;

    final ring = SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.arenaDeep,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 1),
              ],
            ),
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.arenaRaised,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
            ),
          ),
          Text(
            '$secondsLeft',
            // Pinned LTR so the countdown reads as a numeral in both scripts.
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: widget.diameter * 0.36,
              color: accent,
            ),
          ),
        ],
      ),
    );

    if (!isUrgent) return ring;
    return ring
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.08, duration: 500.ms, curve: Curves.easeInOut);
  }
}
