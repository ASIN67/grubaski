import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'macro_progress_ring.dart';

/// A primary dashboard card presenting total daily calories consumed vs. goal
/// alongside animated macronutrient progress bars (Protein, Carbs, Fat).
class CalorieSummaryCard extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesGoal;
  final double proteinConsumed;
  final double proteinGoal;
  final double carbsConsumed;
  final double carbsGoal;
  final double fatConsumed;
  final double fatGoal;
  final VoidCallback? onTap;
  final VoidCallback? onAskAiPressed;

  CalorieSummaryCard({
    super.key,
    required num caloriesConsumed,
    required num caloriesGoal,
    required num proteinConsumed,
    required num proteinGoal,
    required num carbsConsumed,
    required num carbsGoal,
    required num fatConsumed,
    required num fatGoal,
    this.onTap,
    this.onAskAiPressed,
  })  : caloriesConsumed = caloriesConsumed.toDouble(),
        caloriesGoal = caloriesGoal.toDouble(),
        proteinConsumed = proteinConsumed.toDouble(),
        proteinGoal = proteinGoal.toDouble(),
        carbsConsumed = carbsConsumed.toDouble(),
        carbsGoal = carbsGoal.toDouble(),
        fatConsumed = fatConsumed.toDouble(),
        fatGoal = fatGoal.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final remainingKcal = (caloriesGoal - caloriesConsumed).round();
    final isOverflow = caloriesConsumed > caloriesGoal && caloriesGoal > 0;

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
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.heroCardGradient : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Top Header ---
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.caloriesOn(context),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Kalorie i makroskładniki',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverflow
                              ? theme.colorScheme.error.withOpacity(0.12)
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOverflow
                              ? '+${remainingKcal.abs()} kcal ponad'
                              : 'Cel: ${caloriesGoal.round()} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOverflow
                                ? theme.colorScheme.error
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // --- Main Progress Section ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(13) / 13;
                    final isCompact = constraints.maxWidth < 312 * scale;

                    final ringWidget = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MacroProgressRing(
                          consumedCalories: caloriesConsumed,
                          goalCalories: caloriesGoal,
                          size: 122,
                          strokeWidth: 10,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Spożyto: ${caloriesConsumed.round()} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    );

                    final barsWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MacroProgressBar(
                          label: 'Białko',
                          consumed: proteinConsumed,
                          goal: proteinGoal,
                          color: AppColors.protein,
                          gradient: AppColors.proteinGradient,
                        ),
                        const SizedBox(height: 14),
                        _MacroProgressBar(
                          label: 'Węglowodany',
                          consumed: carbsConsumed,
                          goal: carbsGoal,
                          color: AppColors.carbs,
                          gradient: AppColors.carbsGradient,
                        ),
                        const SizedBox(height: 14),
                        _MacroProgressBar(
                          label: 'Tłuszcze',
                          consumed: fatConsumed,
                          goal: fatGoal,
                          color: AppColors.fat,
                          gradient: AppColors.fatGradient,
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          Center(child: ringWidget),
                          const SizedBox(height: 18),
                          barsWidget,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ringWidget,
                        const SizedBox(width: 16),
                        Expanded(child: barsWidget),
                      ],
                    );
                  },
                ),

                if (onAskAiPressed != null && !isOverflow && remainingKcal > 50) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAskAiPressed,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEC4899)
                                  .withOpacity(isDark ? 0.18 : 0.10),
                              AppColors.primary
                                  .withOpacity(isDark ? 0.18 : 0.10),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFEC4899)
                                .withOpacity(isDark ? 0.40 : 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899).withOpacity(0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Brakuje Ci $remainingKcal kcal? Dobierz posiłek z AI ✨',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFFF472B6)
                                  : const Color(0xFFDB2777),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated horizontal progress bar for a single macronutrient.
class _MacroProgressBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color color;
  final LinearGradient gradient;

  const _MacroProgressBar({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final safeGoal = goal > 0 ? goal : 1.0;
    final progress = (consumed / safeGoal).clamp(0.0, 1.0);
    final remaining = (goal - consumed);
    final isOver = consumed > goal && goal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + Values Row
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(
                      text: '${_formatGrams(consumed)} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    TextSpan(text: '/ ${goal.toStringAsFixed(0)} g'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 7,
            width: double.infinity,
            color: isDark ? AppColors.darkProgressTrack : AppColors.lightBorder,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Remaining note
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            isOver
                ? '+${_formatGrams(consumed - goal)} g ponad cel'
                : 'pozostało ${_formatGrams(remaining)} g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isOver
                  ? theme.colorScheme.error
                  : AppColors.textMuted(context),
            ),
          ),
        ),
      ],
    );
  }

  String _formatGrams(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}
