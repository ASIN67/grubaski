import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A circular progress gauge displaying caloric progress against a daily goal.
/// Supports smooth animated progress, rounded stroke caps, gradient strokes,
/// and clear visual feedback when caloric limits are exceeded.
class MacroProgressRing extends StatefulWidget {
  final double consumedCalories;
  final double goalCalories;
  final double size;
  final double strokeWidth;
  final bool animate;
  final Duration animationDuration;
  final Widget? centerChild;

  MacroProgressRing({
    super.key,
    required num consumedCalories,
    required num goalCalories,
    this.size = 140.0,
    this.strokeWidth = 11.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 900),
    this.centerChild,
  })  : consumedCalories = consumedCalories.toDouble(),
        goalCalories = goalCalories.toDouble();

  @override
  State<MacroProgressRing> createState() => _MacroProgressRingState();
}

class _MacroProgressRingState extends State<MacroProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _updateProgress(animate: widget.animate);
  }

  @override
  void didUpdateWidget(covariant MacroProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.animationDuration;
    if (oldWidget.consumedCalories != widget.consumedCalories ||
        oldWidget.goalCalories != widget.goalCalories ||
        oldWidget.animate != widget.animate) {
      _updateProgress(animate: widget.animate);
    }
  }

  void _updateProgress({required bool animate}) {
    final double safeGoal =
        widget.goalCalories > 0 ? widget.goalCalories : 2000.0;
    _targetProgress = (widget.consumedCalories / safeGoal).clamp(0.0, 1.5);

    final double beginVal = _animation?.value ?? 0.0;

    if (animate) {
      _animation = Tween<double>(
        begin: beginVal,
        end: _targetProgress,
      ).animate(
        _controller.drive(CurveTween(curve: Curves.easeOutCubic)),
      );
      _controller.forward(from: 0.0);
    } else {
      _animation = AlwaysStoppedAnimation<double>(_targetProgress);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverflow = widget.consumedCalories > widget.goalCalories &&
        widget.goalCalories > 0;
    final remainingCalories =
        (widget.goalCalories - widget.consumedCalories).round();

    final anim = _animation ?? const AlwaysStoppedAnimation<double>(0.0);

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: anim.value,
                  strokeWidth: widget.strokeWidth,
                  trackColor: isDark
                      ? AppColors.darkProgressTrack
                      : AppColors.lightBorder,
                  isOverflow: isOverflow,
                ),
              ),
              widget.centerChild ??
                  Padding(
                    padding: EdgeInsets.all(widget.strokeWidth + 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _DefaultCenterContent(
                        remaining: remainingCalories,
                        isOverflow: isOverflow,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final bool isOverflow;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.isOverflow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // 2. Active Progress Arc
    const startAngle = -math.pi / 2; // Starts from top (12 o'clock)
    final sweepAngle = 2 * math.pi * math.min(progress, 1.0);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    progressPaint.shader =
        (isOverflow ? AppColors.caloriesGradient : AppColors.primaryGradient)
            .createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // 3. Overflow Indicator Arc (if progress > 1.0)
    if (progress > 1.0) {
      final overflowSweepAngle = 2 * math.pi * math.min(progress - 1.0, 1.0);
      final overflowPaint = Paint()
        ..color = AppColors.calorieOverflow
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
          rect, startAngle, overflowSweepAngle, false, overflowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isOverflow != isOverflow ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _DefaultCenterContent extends StatelessWidget {
  final int remaining;
  final bool isOverflow;

  const _DefaultCenterContent({
    required this.remaining,
    required this.isOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryText =
        isOverflow ? '+${remaining.abs()}' : remaining.toString();

    final label = isOverflow ? 'ponad limit' : 'pozostało';
    final labelColor =
        isOverflow ? theme.colorScheme.error : AppColors.textSecondary(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isOverflow
                ? theme.colorScheme.error
                : AppColors.textPrimary(context),
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: labelColor,
            height: 1.1,
          ),
        ),
        Text(
          'kcal',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted(context),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
