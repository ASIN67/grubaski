import 'dart:math';
import '../models/user_profile.dart';

/// Calculation output data structure holding metabolic rates and macronutrient targets.
class NutritionCalculationResult {
  /// Basal Metabolic Rate (BMR) in kcal.
  final int bmr;

  /// Total Daily Energy Expenditure (TDEE) in kcal.
  final int tdee;

  /// Recommended daily caloric target adjusted for user's goal.
  final int dailyCalories;

  /// Recommended daily protein intake in grams (2.0 g/kg body weight).
  final int proteinGrams;

  /// Recommended daily carbohydrates intake in grams (remaining caloric balance).
  final int carbsGrams;

  /// Recommended daily fat intake in grams (25% of total caloric intake).
  final int fatGrams;

  /// Recommended daily water intake in milliliters (35 ml / kg body weight).
  final int waterGoalMl;

  /// Inferred or specified weight goal.
  final WeightGoal goal;

  /// Weekly pace in kg (e.g. 0.5 kg/week).
  final double weeklyPaceKg;

  /// Caloric offset applied per day (negative for deficit, positive for surplus).
  final int calorieOffset;

  /// Estimated weeks needed to reach the target weight.
  final int estimatedWeeks;

  const NutritionCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.waterGoalMl,
    this.goal = WeightGoal.maintenance,
    this.weeklyPaceKg = 0.5,
    this.calorieOffset = 0,
    this.estimatedWeeks = 0,
  });
}

/// Utility class implementing the Mifflin-St Jeor equation and standard sports
/// nutrition macronutrient distribution formulas.
class NutritionCalculator {
  const NutritionCalculator._();

  /// Automatically deduces the [WeightGoal] by comparing current and target weights.
  static WeightGoal deduceGoal({
    required double currentWeightKg,
    required double targetWeightKg,
  }) {
    final diff = targetWeightKg - currentWeightKg;
    if (diff < -0.2) {
      return WeightGoal.reduction;
    } else if (diff > 0.2) {
      return WeightGoal.surplus;
    } else {
      return WeightGoal.maintenance;
    }
  }

  /// Computes daily caloric deficit or surplus based on target weekly weight change in kg.
  /// 1 kg of body fat ≈ 7700 kcal.
  /// Daily offset = (weeklyPaceKg * 7700) / 7 = weeklyPaceKg * 1100 kcal / day.
  static int calculateCalorieOffset({
    required WeightGoal goal,
    required double weeklyPaceKg,
  }) {
    if (goal == WeightGoal.maintenance) return 0;
    final dailyKcal = (weeklyPaceKg * 1100.0).round();
    return goal == WeightGoal.reduction ? -dailyKcal : dailyKcal;
  }

  /// Calculates estimated weeks needed to reach the target weight.
  static int calculateEstimatedWeeks({
    required double currentWeightKg,
    required double targetWeightKg,
    required double weeklyPaceKg,
  }) {
    if (weeklyPaceKg <= 0.05) return 0;
    final diff = (targetWeightKg - currentWeightKg).abs();
    if (diff <= 0.1) return 0;
    return (diff / weeklyPaceKg).ceil();
  }

  /// Calculates complete nutritional goals based on biometric parameters, weekly pace, and goal.
  ///
  /// Formula steps:
  /// 1. BMR (Mifflin-St Jeor):
  ///    - Men:   (10 * weight) + (6.25 * height) - (5 * age) + 5
  ///    - Women: (10 * weight) + (6.25 * height) - (5 * age) - 161
  /// 2. TDEE = BMR * activityMultiplier
  /// 3. Caloric offset from weekly pace (or fallback goal.calorieOffset)
  /// 4. Daily Calories = TDEE + calorieOffset
  /// 5. Protein = 2.0 g / kg body weight (1g protein = 4 kcal)
  /// 6. Fat = 25% of Daily Calories (1g fat = 9 kcal)
  /// 7. Carbs = (Daily Calories - (Protein * 4) - (Fat * 9)) / 4
  /// 8. Water = 35 ml / kg body weight (minimum 2000 ml)
  static NutritionCalculationResult calculate({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
    required ActivityLevel activityLevel,
    WeightGoal? goal,
    double? targetWeightKg,
    double weeklyPaceKg = 0.5,
  }) {
    // Determine goal automatically if target weight is provided, else use passed goal
    final WeightGoal effectiveGoal;
    if (targetWeightKg != null) {
      effectiveGoal = deduceGoal(
        currentWeightKg: weightKg,
        targetWeightKg: targetWeightKg,
      );
    } else {
      effectiveGoal = goal ?? WeightGoal.maintenance;
    }

    // 1. Basal Metabolic Rate (BMR) - Mifflin-St Jeor
    final double rawBmr;
    if (gender == Gender.male) {
      rawBmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + 5.0;
    } else {
      rawBmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) - 161.0;
    }
    final int bmr = max(1000, rawBmr.round());

    // 2. Total Daily Energy Expenditure (TDEE)
    final double rawTdee = bmr * activityLevel.multiplier;
    final int tdee = rawTdee.round();

    // 3. Goal adjustment with weekly pace
    final int calorieOffset = calculateCalorieOffset(
      goal: effectiveGoal,
      weeklyPaceKg: weeklyPaceKg,
    );
    final int rawDailyCalories = tdee + calorieOffset;

    // Safety clamp: Never recommend below essential physiological minimum (1200 for women, 1400 for men)
    final int minimumSafeCalories = gender == Gender.male ? 1400 : 1200;
    final int dailyCalories = max(minimumSafeCalories, rawDailyCalories);

    // 4. Protein calculation: 2.0g per kg of current body weight
    final int proteinGrams = (weightKg * 2.0).round();
    final int proteinCalories = proteinGrams * 4;

    // 5. Fat calculation: 25% of total caloric pool
    final double fatCalories = dailyCalories * 0.25;
    final int fatGrams = max(30, (fatCalories / 9.0).round());
    final int totalFatCalories = fatGrams * 9;

    // 6. Carbohydrates calculation: remaining caloric balance
    final int remainingCalories = dailyCalories - proteinCalories - totalFatCalories;
    final int carbsGrams = max(20, (remainingCalories / 4.0).round());

    // 7. Water goal: 35 ml per kg of body weight, rounded to nearest 50 ml (min 2000 ml)
    final int rawWaterMl = (weightKg * 35.0).round();
    final int roundedWaterMl = ((rawWaterMl + 25) ~/ 50) * 50;
    final int waterGoalMl = max(2000, roundedWaterMl);

    // 8. Estimated weeks to reach goal
    final int estimatedWeeks = targetWeightKg != null
        ? calculateEstimatedWeeks(
            currentWeightKg: weightKg,
            targetWeightKg: targetWeightKg,
            weeklyPaceKg: weeklyPaceKg,
          )
        : 0;

    return NutritionCalculationResult(
      bmr: bmr,
      tdee: tdee,
      dailyCalories: dailyCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      waterGoalMl: waterGoalMl,
      goal: effectiveGoal,
      weeklyPaceKg: weeklyPaceKg,
      calorieOffset: calorieOffset,
      estimatedWeeks: estimatedWeeks,
    );
  }

  /// Calculates recommended water intake for given body weight.
  static int calculateWaterGoalMl(double weightKg) {
    final int rawWaterMl = (weightKg * 35.0).round();
    final int roundedWaterMl = ((rawWaterMl + 25) ~/ 50) * 50;
    return max(2000, roundedWaterMl);
  }
}
