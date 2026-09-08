import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// A circular countdown ring for the active round. Ticks locally once a
/// second from [roundStartedAt] — the actual authority on "time's up" is
/// still the server (see `functions/src/scoring/expireStaleRounds.ts`),
/// this is just the visible clock.
class DuelTimer extends StatefulWidget {
  const DuelTimer({
    super.key,
    required this.roundStartedAt,
    this.timeLimitSeconds = AppConstants.roundTimeLimitSeconds,
    this.onTimeUp,
  });

  final DateTime roundStartedAt;
  final int timeLimitSeconds;
  final VoidCallback? onTimeUp;

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
    final progress = _remaining.inMilliseconds / (widget.timeLimitSeconds * 1000);
    final isUrgent = _remaining.inSeconds <= 5;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: AppColors.surfaceBorder,
            valueColor: AlwaysStoppedAnimation(isUrgent ? AppColors.error : AppColors.gold),
          ),
          Text(
            '${_remaining.inSeconds}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isUrgent ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
