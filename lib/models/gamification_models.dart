import 'package:flutter/material.dart';
import 'user_profile.dart';

/// Comprehensive state of user's calorie and habit streak.
class StreakInfo {
  final int currentStreak;
  final int bestStreak;
  final bool isTodayAchieved;
  final bool isYesterdayAchieved;
  final bool isTodayLogged;
  final WeightGoal goal;
  final int targetCalories;
  final double todayCalories;
  final String headline;
  final String subtitle;
  final String ruleExplanation;
  final double todayProgress;

  const StreakInfo({
    required this.currentStreak,
    required this.bestStreak,
    required this.isTodayAchieved,
    required this.isYesterdayAchieved,
    required this.isTodayLogged,
    required this.goal,
    required this.targetCalories,
    required this.todayCalories,
    required this.headline,
    required this.subtitle,
    required this.ruleExplanation,
    required this.todayProgress,
  });

  /// True if user currently has an active streak (either achieved today or kept from yesterday).
  bool get hasActiveStreak => currentStreak > 0;
}

/// Category of an in-app achievement.
enum AchievementCategory {
  streak,
  hydration,
  nutrition,
  weight,
  discovery;

  String get displayName {
    switch (this) {
      case AchievementCategory.streak:
        return 'Passa';
      case AchievementCategory.hydration:
        return 'Nawodnienie';
      case AchievementCategory.nutrition:
        return 'Odżywianie';
      case AchievementCategory.weight:
        return 'Waga';
      case AchievementCategory.discovery:
        return 'Odkrywanie';
    }
  }
}

/// A badge or milestone rewarded for consistent habits and goal achievement.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final String progressLabel;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
    required this.progressLabel,
  });
}

/// A single coordinate point along the weight history and forecast timeline.
class ForecastDataPoint {
  final DateTime date;
  final double weightKg;
  final bool isProjected;

  const ForecastDataPoint({
    required this.date,
    required this.weightKg,
    required this.isProjected,
  });
}

/// Dynamic MacroFactor-style goal prediction based on actual or planned caloric balance.
class WeightForecast {
  final double currentWeightKg;
  final double targetWeightKg;
  final WeightGoal goal;
  final double dailyDeficitOrSurplusKcal;
  final double weeklyPaceKg;
  final int? daysToGoal;
  final DateTime? estimatedDate;
  final String headline;
  final String description;
  final bool isGoalReached;
  final bool isPaceZeroOrOpposite;
  final List<ForecastDataPoint> trajectory;

  const WeightForecast({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.goal,
    required this.dailyDeficitOrSurplusKcal,
    required this.weeklyPaceKg,
    this.daysToGoal,
    this.estimatedDate,
    required this.headline,
    required this.description,
    required this.isGoalReached,
    required this.isPaceZeroOrOpposite,
    required this.trajectory,
  });
}
