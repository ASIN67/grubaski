import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/diary_repository.dart';
import '../repositories/water_repository.dart';
import '../repositories/weight_repository.dart';
import '../utils/date_formatter.dart';

/// Centralized service calculating user habit streaks, dynamic MacroFactor-style
/// weight forecasts, and achievement milestones.
class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  /// Energy equivalent in kilocalories required to gain or lose 1 kg of body fat.
  static const double kcalPerKgFat = 7700.0;

  /// Verifies whether consumed calories on a given day satisfy the user's diet goal.
  ///
  /// User specifications:
  /// - Maintenance (Utrzymanie): target +- 100 kcal
  /// - Surplus (Masa): from (target - 100 kcal) and upwards
  /// - Reduction (Redukcja): up to (target + 100 kcal) and downwards (min. 400 kcal logged)
  static bool isDayGoalAchieved({
    required double consumedCalories,
    required int targetCalories,
    required WeightGoal goal,
  }) {
    switch (goal) {
      case WeightGoal.maintenance:
        return consumedCalories >= (targetCalories - 100) &&
            consumedCalories <= (targetCalories + 100);
      case WeightGoal.surplus:
        return consumedCalories >= (targetCalories - 100);
      case WeightGoal.reduction:
        return consumedCalories <= (targetCalories + 100) &&
            consumedCalories >= 400.0;
    }
  }

  /// Calculates the current and best streak of contiguous days adhering to the goal.
  StreakInfo calculateStreak({
    required DiaryRepository diaryRepo,
    required UserProfile? profile,
  }) {
    final target = profile?.dailyCaloriesGoal ?? 2000;
    final goal = profile?.goal ?? WeightGoal.reduction;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todaySummary = diaryRepo.getDailySummaryForDate(today);
    final double todayCalories = todaySummary.totalCalories;
    final bool isTodayLogged = todayCalories >= 400.0;
    final bool isTodayAchieved = isDayGoalAchieved(
      consumedCalories: todayCalories,
      targetCalories: target,
      goal: goal,
    );

    final yesterdaySummary = diaryRepo.getDailySummaryForDate(yesterday);
    final double yesterdayCalories = yesterdaySummary.totalCalories;
    final bool isYesterdayAchieved = isDayGoalAchieved(
      consumedCalories: yesterdayCalories,
      targetCalories: target,
      goal: goal,
    );

    int currentStreak = 0;

    if (isTodayAchieved) {
      // Today counts as day 1 + count backwards consecutively
      currentStreak = 1;
      var checkDate = yesterday;
      while (true) {
        final daySummary = diaryRepo.getDailySummaryForDate(checkDate);
        if (isDayGoalAchieved(
          consumedCalories: daySummary.totalCalories,
          targetCalories: target,
          goal: goal,
        )) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    } else if (isYesterdayAchieved) {
      // Today is in progress (not yet finalized or reached), but streak from yesterday is active!
      currentStreak = 1;
      var checkDate = yesterday.subtract(const Duration(days: 1));
      while (true) {
        final daySummary = diaryRepo.getDailySummaryForDate(checkDate);
        if (isDayGoalAchieved(
          consumedCalories: daySummary.totalCalories,
          targetCalories: target,
          goal: goal,
        )) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    } else {
      // Neither today nor yesterday met the goal
      currentStreak = 0;
    }

    // All-time best streak across entire diary history
    final int bestStreak = _computeHistoricalBestStreak(
      diaryRepo: diaryRepo,
      targetCalories: target,
      goal: goal,
      currentStreak: currentStreak,
    );

    // Polish headline & subtitles
    final String daysWord = currentStreak == 1 ? 'dzień' : 'dni';
    String headline;
    switch (goal) {
      case WeightGoal.reduction:
        headline = currentStreak > 0
            ? '🔥 $currentStreak $daysWord z rzędu w deficycie!'
            : 'Zacznij passę w deficycie!';
      case WeightGoal.surplus:
        headline = currentStreak > 0
            ? '🔥 $currentStreak $daysWord z rzędu na masie!'
            : 'Zacznij passę na masie!';
      case WeightGoal.maintenance:
        headline = currentStreak > 0
            ? '🔥 $currentStreak $daysWord z rzędu w bilansie!'
            : 'Zacznij passę w bilansie!';
    }

    String ruleExplanation;
    switch (goal) {
      case WeightGoal.reduction:
        ruleExplanation =
            'Redukcja: do ${target + 100} kcal (+100 kcal marginesu)';
      case WeightGoal.surplus:
        ruleExplanation =
            'Masa: od ${target - 100} kcal w górę (-100 kcal marginesu)';
      case WeightGoal.maintenance:
        ruleExplanation =
            'Utrzymanie: przedział ${target - 100} – ${target + 100} kcal (±100 kcal)';
    }

    String subtitle;
    if (isTodayAchieved) {
      subtitle =
          'Dzisiaj: ${todayCalories.round()} / $target kcal • Cel dnia zaliczony!';
    } else if (isTodayLogged) {
      if (goal == WeightGoal.reduction && todayCalories > target + 100) {
        final over = (todayCalories - (target + 100)).round();
        subtitle =
            'Dzisiaj: ${todayCalories.round()} / $target kcal • Przekroczono cel o $over kcal';
      } else if (goal == WeightGoal.surplus && todayCalories < target - 100) {
        final remaining = ((target - 100) - todayCalories).round();
        subtitle =
            'Dzisiaj: ${todayCalories.round()} / $target kcal • Brakuje $remaining kcal do zaliczenia';
      } else {
        subtitle =
            'Dzisiaj: ${todayCalories.round()} / $target kcal • W trakcie realizacji';
      }
    } else {
      subtitle = 'Dzisiaj: 0 / $target kcal • Zaloguj posiłki, by utrzymać passę';
    }

    final double todayProgress = target > 0 ? (todayCalories / target) : 0.0;

    return StreakInfo(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isTodayAchieved: isTodayAchieved,
      isYesterdayAchieved: isYesterdayAchieved,
      isTodayLogged: isTodayLogged,
      goal: goal,
      targetCalories: target,
      todayCalories: todayCalories,
      headline: headline,
      subtitle: subtitle,
      ruleExplanation: ruleExplanation,
      todayProgress: todayProgress,
    );
  }

  int _computeHistoricalBestStreak({
    required DiaryRepository diaryRepo,
    required int targetCalories,
    required WeightGoal goal,
    required int currentStreak,
  }) {
    final allEntries = diaryRepo.getAllEntries();
    if (allEntries.isEmpty) return currentStreak;

    // Collect all unique date keys
    final dateKeys = allEntries.map((e) => e.dateKey).toSet().toList();
    final dates = <DateTime>[];
    for (final dk in dateKeys) {
      final parts = dk.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          dates.add(DateTime(y, m, d));
        }
      }
    }

    if (dates.isEmpty) return currentStreak;
    dates.sort((a, b) => a.compareTo(b));

    int maxStreak = currentStreak;
    int run = 0;
    DateTime? prevDate;

    for (final date in dates) {
      final summary = diaryRepo.getDailySummaryForDate(date);
      final achieved = isDayGoalAchieved(
        consumedCalories: summary.totalCalories,
        targetCalories: targetCalories,
        goal: goal,
      );

      if (achieved) {
        if (prevDate != null && date.difference(prevDate).inDays == 1) {
          run++;
        } else {
          run = 1;
        }
        prevDate = date;
        if (run > maxStreak) {
          maxStreak = run;
        }
      } else {
        run = 0;
        prevDate = null;
      }
    }

    return math.max(maxStreak, currentStreak);
  }

  /// Calculates dynamic MacroFactor-style weight prediction and trajectory timeline.
  WeightForecast calculateForecast({
    required UserProfile? profile,
    required WeightRepository weightRepo,
    required DiaryRepository diaryRepo,
  }) {
    final currentWeight = weightRepo.getLatestWeightEntry()?.weightKg ??
        profile?.startWeightKg ??
        75.0;
    final targetWeight = profile?.targetWeightKg ?? 70.0;
    final goal = profile?.goal ?? WeightGoal.reduction;
    final targetCalories = profile?.dailyCaloriesGoal ?? 2000;

    // Calculate TDEE using Mifflin-St Jeor formula
    final double height = profile?.heightCm ?? 175.0;
    final int age = profile?.age ?? 25;
    final Gender gender = profile?.gender ?? Gender.male;
    final double activityMultiplier =
        profile?.activityLevel.multiplier ?? 1.375;

    final double bmr = (gender == Gender.male)
        ? (10.0 * currentWeight) + (6.25 * height) - (5.0 * age) + 5.0
        : (10.0 * currentWeight) + (6.25 * height) - (5.0 * age) - 161.0;
    final double tdee = bmr * activityMultiplier;

    // Average caloric balance over recent 7-14 logged days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double recentCaloriesSum = 0.0;
    int loggedDaysCount = 0;
    for (int i = 0; i < 14; i++) {
      final d = today.subtract(Duration(days: i));
      final sum = diaryRepo.getDailySummaryForDate(d);
      if (sum.totalCalories >= 400.0) {
        recentCaloriesSum += sum.totalCalories;
        loggedDaysCount++;
      }
    }

    // Determine actual daily deficit/surplus (or planned if insufficient data)
    final double dailyAverageIntake = loggedDaysCount >= 2
        ? (recentCaloriesSum / loggedDaysCount)
        : targetCalories.toDouble();

    final double dailyBalanceKcal = dailyAverageIntake - tdee; // <0 deficit, >0 surplus

    final double kgPerDay = dailyBalanceKcal.abs() / kcalPerKgFat;
    final double weeklyPaceKg = kgPerDay * 7.0;

    final double weightDifference = (currentWeight - targetWeight).abs();
    final bool isGoalReached = weightDifference <= 0.2;

    bool isPaceZeroOrOpposite = false;
    int? daysToGoal;
    DateTime? estimatedDate;
    String headline;
    String description;

    if (isGoalReached) {
      headline = 'Waga docelowa została osiągnięta! 🎉';
      description =
          'Ważysz ${currentWeight.toStringAsFixed(1)} kg. Twój aktualny bilans to utrzymanie wagi (~${tdee.round()} kcal/dzień).';
    } else if (goal == WeightGoal.reduction) {
      if (currentWeight < targetWeight) {
        headline = 'Waga poniżej celu (${currentWeight.toStringAsFixed(1)} kg)';
        description =
            'Twoja obecna waga jest niższa niż wyznaczony cel ${targetWeight.toStringAsFixed(1)} kg.';
      } else if (dailyBalanceKcal >= -50.0) {
        isPaceZeroOrOpposite = true;
        headline = 'Brak aktywnego deficytu kalorycznego';
        description =
            'Średnie spożycie (${dailyAverageIntake.round()} kcal) jest równe lub wyższe od Twojego zapotrzebowania (${tdee.round()} kcal). Aby chudnąć wg planu (~0.5 kg/tydzień), trzymaj się limitu $targetCalories kcal.';
      } else {
        final double effectiveDailyLossKg = (-dailyBalanceKcal) / kcalPerKgFat;
        final double daysNeeded = (currentWeight - targetWeight) / effectiveDailyLossKg;
        daysToGoal = math.max(1, daysNeeded.round());
        estimatedDate = now.add(Duration(days: daysToGoal));

        final weeks = (daysToGoal / 7.0).ceil();
        final polishDateStr = DateFormatter.formatPolishDisplayDate(estimatedDate);
        headline =
            'Osiągniesz ${targetWeight.toStringAsFixed(1)} kg za ok. $weeks tyg. ($polishDateStr)';
        description =
            'Utrzymując obecne średnie tempo (~${(-dailyBalanceKcal).round()} kcal deficytu dziennie), redukujesz ok. ${weeklyPaceKg.toStringAsFixed(2)} kg na tydzień.';
      }
    } else if (goal == WeightGoal.surplus) {
      if (currentWeight > targetWeight) {
        headline = 'Waga powyżej celu (${currentWeight.toStringAsFixed(1)} kg)';
        description =
            'Osiągnąłeś już wyznaczoną masę ${targetWeight.toStringAsFixed(1)} kg.';
      } else if (dailyBalanceKcal <= 50.0) {
        isPaceZeroOrOpposite = true;
        headline = 'Brak aktywnej nadwyżki na masę';
        description =
            'Średnie spożycie (${dailyAverageIntake.round()} kcal) jest poniżej zapotrzebowania (${tdee.round()} kcal). Aby budować masę, zjadaj powyżej ${targetCalories - 100} kcal.';
      } else {
        final double effectiveDailyGainKg = dailyBalanceKcal / kcalPerKgFat;
        final double daysNeeded = (targetWeight - currentWeight) / effectiveDailyGainKg;
        daysToGoal = math.max(1, daysNeeded.round());
        estimatedDate = now.add(Duration(days: daysToGoal));

        final weeks = (daysToGoal / 7.0).ceil();
        final polishDateStr = DateFormatter.formatPolishDisplayDate(estimatedDate);
        headline =
            'Osiągniesz ${targetWeight.toStringAsFixed(1)} kg za ok. $weeks tyg. ($polishDateStr)';
        description =
            'Utrzymując obecne średnie tempo (+${dailyBalanceKcal.round()} kcal nadwyżki dziennie), przybierasz ok. ${weeklyPaceKg.toStringAsFixed(2)} kg na tydzień.';
      }
    } else {
      // Maintenance
      headline = 'Utrzymanie wagi w równowadze';
      description =
          'Twoje średnie spożycie (${dailyAverageIntake.round()} kcal) utrzymuje stabilną wagę przy zapotrzebowaniu ${tdee.round()} kcal/dzień.';
    }

    // Generate forecast trajectory coordinates
    final trajectory = _generateTrajectory(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      goal: goal,
      estimatedDays: daysToGoal ?? (goal == WeightGoal.maintenance ? 30 : 60),
    );

    return WeightForecast(
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      goal: goal,
      dailyDeficitOrSurplusKcal: dailyBalanceKcal,
      weeklyPaceKg: weeklyPaceKg,
      daysToGoal: daysToGoal,
      estimatedDate: estimatedDate,
      headline: headline,
      description: description,
      isGoalReached: isGoalReached,
      isPaceZeroOrOpposite: isPaceZeroOrOpposite,
      trajectory: trajectory,
    );
  }

  List<ForecastDataPoint> _generateTrajectory({
    required double currentWeight,
    required double targetWeight,
    required WeightGoal goal,
    required int estimatedDays,
  }) {
    final points = <ForecastDataPoint>[];
    final now = DateTime.now();
    points.add(ForecastDataPoint(
      date: now,
      weightKg: currentWeight,
      isProjected: false,
    ));

    final steps = 5;
    final int safeDays = math.min(180, math.max(10, estimatedDays));
    final double stepDays = safeDays / steps;

    for (int i = 1; i <= steps; i++) {
      final daysOffset = (stepDays * i).round();
      final date = now.add(Duration(days: daysOffset));
      final fraction = i / steps.toDouble();
      final projectedWeight =
          currentWeight + (targetWeight - currentWeight) * fraction;

      points.add(ForecastDataPoint(
        date: date,
        weightKg: projectedWeight,
        isProjected: true,
      ));
    }

    return points;
  }

  /// Evaluates full set of badges and milestones against recorded data.
  List<Achievement> evaluateAchievements({
    required DiaryRepository diaryRepo,
    required WaterRepository waterRepo,
    required WeightRepository weightRepo,
    required UserProfile? profile,
    required StreakInfo streakInfo,
  }) {
    final achievements = <Achievement>[];
    final targetWater = profile?.waterGoalMl ?? 2500;
    final targetProtein = profile?.proteinGoalGrams.toDouble() ?? 150.0;
    final allMealEntries = diaryRepo.getAllEntries();
    final allWeightEntries = weightRepo.getAllWeightEntries();

    // 1. STREAK BADGES
    _addBadge(
      achievements,
      id: 'streak_3',
      title: 'Iskra Nawyków',
      description: 'Utrzymaj passę przez 3 dni z rzędu.',
      icon: Icons.local_fire_department_rounded,
      category: AchievementCategory.streak,
      current: streakInfo.currentStreak.toDouble(),
      target: 3.0,
    );

    _addBadge(
      achievements,
      id: 'streak_7',
      title: 'Płomień Dyscypliny',
      description: 'Utrzymaj passę przez pełny tydzień (7 dni).',
      icon: Icons.whatshot_rounded,
      category: AchievementCategory.streak,
      current: streakInfo.currentStreak.toDouble(),
      target: 7.0,
    );

    _addBadge(
      achievements,
      id: 'streak_14',
      title: 'Żelazna Konsekwencja',
      description: 'Utrzymaj passę przez 14 dni z rzędu.',
      icon: Icons.military_tech_rounded,
      category: AchievementCategory.streak,
      current: streakInfo.currentStreak.toDouble(),
      target: 14.0,
    );

    _addBadge(
      achievements,
      id: 'streak_30',
      title: 'Tytan Formy',
      description: 'Zrealizuj pełny miesiąc (30 dni) passy!',
      icon: Icons.workspace_premium_rounded,
      category: AchievementCategory.streak,
      current: streakInfo.currentStreak.toDouble(),
      target: 30.0,
    );

    // 2. HYDRATION BADGES
    final allWaterLogs = waterRepo.getAllLogs();
    final daysMetWater = allWaterLogs.where((l) => l.amountMl >= targetWater).length;
    final totalWaterConsumed =
        allWaterLogs.fold<int>(0, (sum, l) => sum + l.amountMl);

    _addBadge(
      achievements,
      id: 'water_first',
      title: 'Pierwsza Kropla',
      description: 'Zapisz pierwsze nawodnienie w aplikacji.',
      icon: Icons.water_drop_rounded,
      category: AchievementCategory.hydration,
      current: totalWaterConsumed > 0 ? 1.0 : 0.0,
      target: 1.0,
    );

    _addBadge(
      achievements,
      id: 'water_7',
      title: 'Wodny Mistrz',
      description: 'Wypij 100% dziennego celu wody przez 7 dni.',
      icon: Icons.opacity_rounded,
      category: AchievementCategory.hydration,
      current: daysMetWater.toDouble(),
      target: 7.0,
    );

    _addBadge(
      achievements,
      id: 'water_14',
      title: 'Ocean Energii',
      description: 'Osiągnij cel nawodnienia przez 14 dni.',
      icon: Icons.waves_rounded,
      category: AchievementCategory.hydration,
      current: daysMetWater.toDouble(),
      target: 14.0,
    );

    // 3. NUTRITION & MACROS
    final uniqueDates = allMealEntries.map((e) => e.dateKey).toSet();
    int daysMetProtein = 0;
    int daysExactCalories = 0;

    for (final dk in uniqueDates) {
      final summary = diaryRepo.getDailySummary(dk);
      if (summary.totalProtein >= targetProtein) {
        daysMetProtein++;
      }
      final target = profile?.dailyCaloriesGoal ?? 2000;
      if ((summary.totalCalories - target).abs() <= 50.0 &&
          summary.totalCalories >= 400.0) {
        daysExactCalories++;
      }
    }

    _addBadge(
      achievements,
      id: 'protein_monster',
      title: 'Białkowy Potwór',
      description: 'Osiągnij 100% celu białka przez 5 dni.',
      icon: Icons.fitness_center_rounded,
      category: AchievementCategory.nutrition,
      current: daysMetProtein.toDouble(),
      target: 5.0,
    );

    _addBadge(
      achievements,
      id: 'calorie_sniper',
      title: 'Snajper Kalorii',
      description: 'Traf w swój cel kalorii z dokładnością do 50 kcal!',
      icon: Icons.gps_fixed_rounded,
      category: AchievementCategory.nutrition,
      current: daysExactCalories > 0 ? 1.0 : 0.0,
      target: 1.0,
    );

    _addBadge(
      achievements,
      id: 'meals_10',
      title: 'Świadomy Talerz',
      description: 'Zapisz 10 posiłków w swoim dzienniku.',
      icon: Icons.restaurant_rounded,
      category: AchievementCategory.nutrition,
      current: allMealEntries.length.toDouble(),
      target: 10.0,
    );

    _addBadge(
      achievements,
      id: 'meals_50',
      title: 'Koneser Dziennika',
      description: 'Zapisz 50 posiłków w swoim dzienniku.',
      icon: Icons.menu_book_rounded,
      category: AchievementCategory.nutrition,
      current: allMealEntries.length.toDouble(),
      target: 50.0,
    );

    // 4. DISCOVERY & SCANNER
    final hasBarcodeEntry = allMealEntries.any((e) => e.product.barcode != null);
    final hasCustomOrRecipe = allMealEntries.any((e) => e.product.isCustom || e.product.isRecipe);

    _addBadge(
      achievements,
      id: 'scanner_first',
      title: 'Cyfrowy Skaner',
      description: 'Dodaj produkt za pomocą skanera kodów kreskowych.',
      icon: Icons.qr_code_scanner_rounded,
      category: AchievementCategory.discovery,
      current: hasBarcodeEntry ? 1.0 : 0.0,
      target: 1.0,
    );

    _addBadge(
      achievements,
      id: 'custom_recipe',
      title: 'Domowy Szef Kuchni',
      description: 'Dodaj do dziennika własny przepis lub produkt autorski.',
      icon: Icons.soup_kitchen_rounded,
      category: AchievementCategory.discovery,
      current: hasCustomOrRecipe ? 1.0 : 0.0,
      target: 1.0,
    );

    // 5. WEIGHT PROGRESS
    final startWeight = profile?.startWeightKg ?? 75.0;
    final targetWeight = profile?.targetWeightKg ?? 70.0;
    final latestWeight = weightRepo.getLatestWeightEntry()?.weightKg ?? startWeight;

    _addBadge(
      achievements,
      id: 'weight_first',
      title: 'Punkt Kontrolny',
      description: 'Zapisz swój pierwszy pomiar wagi.',
      icon: Icons.monitor_weight_rounded,
      category: AchievementCategory.weight,
      current: allWeightEntries.isNotEmpty ? 1.0 : 0.0,
      target: 1.0,
    );

    final totalWeightToChange = (startWeight - targetWeight).abs();
    final weightChanged = (startWeight - latestWeight).abs();
    final halfwayReached = totalWeightToChange > 0 &&
        weightChanged >= (totalWeightToChange * 0.5) &&
        allWeightEntries.length >= 2;

    _addBadge(
      achievements,
      id: 'weight_halfway',
      title: 'Półmetek Sukcesu',
      description: 'Osiągnij 50% drogi do swojej wagi docelowej.',
      icon: Icons.flag_rounded,
      category: AchievementCategory.weight,
      current: halfwayReached ? 1.0 : (totalWeightToChange > 0 ? (weightChanged / (totalWeightToChange * 0.5)).clamp(0.0, 0.99) : 0.0),
      target: 1.0,
    );

    return achievements;
  }

  void _addBadge(
    List<Achievement> list, {
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required AchievementCategory category,
    required double current,
    required double target,
  }) {
    final double rawProgress = target > 0 ? (current / target) : 0.0;
    final double clampedProgress = rawProgress.clamp(0.0, 1.0);
    final bool isUnlocked = current >= target;

    String progressLabel;
    if (isUnlocked) {
      progressLabel = 'Zdobyte!';
    } else if (target <= 1.0) {
      progressLabel = '0 / 1';
    } else {
      progressLabel = '${current.toInt()} / ${target.toInt()}';
    }

    list.add(Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      category: category,
      isUnlocked: isUnlocked,
      progress: clampedProgress,
      progressLabel: progressLabel,
    ));
  }
}
