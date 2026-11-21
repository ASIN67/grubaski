import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// An interactive hydration card displaying daily water intake vs. goal
/// with an animated liquid glass indicator and quick adjustment buttons.
class WaterTrackerCard extends StatelessWidget {
  final int consumedMl;
  final int goalMl;
  final ValueChanged<int>? onWaterDelta;
  final ValueChanged<int>? onWaterChanged;
  final void Function(int amount)? onAddWater;
  final void Function(int amount)? onRemoveWater;
  final VoidCallback? onTap;

  const WaterTrackerCard({
    super.key,
    required this.consumedMl,
    this.goalMl = 2500,
    this.onWaterDelta,
    this.onWaterChanged,
    this.onAddWater,
    this.onRemoveWater,
    this.onTap,
  });

  void _modifyWater(int delta) {
    final int safeDelta;
    if (delta < 0 && consumedMl + delta < 0) {
      safeDelta = -consumedMl;
    } else {
      safeDelta = delta;
    }

    final int newAmount = math.max(0, consumedMl + safeDelta);
    onWaterDelta?.call(safeDelta);
    onWaterChanged?.call(newAmount);
    if (safeDelta > 0) {
      onAddWater?.call(safeDelta);
    } else if (safeDelta < 0) {
      onRemoveWater?.call(-safeDelta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final waterColor = AppColors.waterOn(context);

    final safeGoal = goalMl > 0 ? goalMl : 2000;
    final progress = (consumedMl / safeGoal).clamp(0.0, 1.0);
    final remainingMl = math.max(0, safeGoal - consumedMl);
    final isGoalReached = consumedMl >= safeGoal;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.water
                                .withOpacity(isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.water_drop_rounded,
                            color: waterColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nawodnienie',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                isGoalReached
                                    ? 'Cel osiągnięty'
                                    : 'Pozostało: $remainingMl ml',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isGoalReached
                                      ? waterColor
                                      : AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Progress % Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.water.withOpacity(isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: waterColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Visual Progress Bar & Current / Goal Text ---
              Row(
                children: [
                  // Animated Mini Glass
                  _WaterGlassIndicator(progress: progress),
                  const SizedBox(width: 14),

                  // Volume & Horizontal Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontFamily:
                                        theme.textTheme.bodyMedium?.fontFamily,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$consumedMl ',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/ $safeGoal ml',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Animated Progress Track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 10,
                            width: double.infinity,
                            color: isDark
                                ? AppColors.darkProgressTrack
                                : AppColors.lightBorder,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: progress),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.waterGradient,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // --- Quick Action Buttons Row ---
              Row(
                children: [
                  Expanded(
                    child: _QuickWaterButton(
                      label: '+250 ml',
                      icon: Icons.local_drink_rounded,
                      onTap: () => _modifyWater(250),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickWaterButton(
                      label: '+500 ml',
                      icon: Icons.water_drop_outlined,
                      onTap: () => _modifyWater(500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickWaterButton(
                      label: '−250 ml',
                      icon: Icons.remove_rounded,
                      isDestructive: true,
                      isEnabled: consumedMl > 0,
                      onTap: consumedMl > 0 ? () => _modifyWater(-250) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom painted water glass showing liquid filling up with progress.
class _WaterGlassIndicator extends StatelessWidget {
  final double progress;

  const _WaterGlassIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 54,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(10),
          top: Radius.circular(4),
        ),
        border: Border.all(
          color: AppColors.water.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return FractionallySizedBox(
            heightFactor: value,
            widthFactor: 1.0,
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.waterGradient,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A compact quick-action button for adjusting water quantity.
class _QuickWaterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isEnabled;

  const _QuickWaterButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDestructive
        ? (isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant)
        : (isDark
            ? AppColors.water.withOpacity(0.14)
            : AppColors.waterBackground);

    final foregroundColor = !isEnabled
        ? AppColors.textMuted(context)
        : (isDestructive
            ? AppColors.textSecondary(context)
            : AppColors.waterOn(context));

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foregroundColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
