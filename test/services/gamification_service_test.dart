import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/diary_repository.dart';
import 'package:grubasek/repositories/water_repository.dart';
import 'package:grubasek/repositories/weight_repository.dart';
import 'package:grubasek/services/gamification_service.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/date_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveService hiveService;
  late DiaryRepository diaryRepo;
  late WaterRepository waterRepo;
  late WeightRepository weightRepo;
  final service = GamificationService.instance;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('gamification_test_');
    hiveService = HiveService.instance;
    await hiveService.init(customPath: tempDir.path);
    diaryRepo = DiaryRepository(hiveService: hiveService);
    waterRepo = WaterRepository(hiveService: hiveService);
    weightRepo = WeightRepository(hiveService: hiveService);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await hiveService.mealEntriesBox.clear();
    await hiveService.waterLogsBox.clear();
    await hiveService.weightEntriesBox.clear();
  });

  group('GamificationService - Streak Goal Rules', () {
    test('Maintenance (Utrzymanie) requires calories within +-100 kcal of target', () {
      const target = 2200;
      const goal = WeightGoal.maintenance;

      // Exactly at target
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2200,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // Boundaries: 2100 (target - 100) and 2300 (target + 100)
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2100,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2300,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // Outside bounds
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2099,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2301,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
    });

    test('Surplus (Masa) requires calories from (target - 100 kcal) and upwards', () {
      const target = 3000;
      const goal = WeightGoal.surplus;

      // Lower boundary: 2900 (target - 100)
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2900,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // At target and far above
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 3000,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 3800,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // Below 2900 fails
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 2899,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 1500,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
    });

    test('Reduction (Redukcja) requires calories up to (target + 100 kcal) and downwards with min 400 kcal', () {
      const target = 1800;
      const goal = WeightGoal.reduction;

      // Upper boundary: 1900 (target + 100)
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 1900,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // Deficit values
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 1750,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 1400,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );

      // Lower bound protection (empty or negligible days do not count as reduction)
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 400,
          targetCalories: target,
          goal: goal,
        ),
        isTrue,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 399,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 0,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );

      // Above upper boundary fails
      expect(
        GamificationService.isDayGoalAchieved(
          consumedCalories: 1901,
          targetCalories: target,
          goal: goal,
        ),
        isFalse,
      );
    });
  });

  group('GamificationService - Streak Calculation & History', () {
    const dummyProduct = FoodProduct(
      id: 'test-product',
      name: 'Test Food',
      caloriesPer100g: 200.0,
      proteinPer100g: 10.0,
      carbsPer100g: 20.0,
      fatPer100g: 5.0,
    );

    test('calculates contiguous multi-day streak and all-time best streak', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      const profile = UserProfile(
        gender: Gender.male,
        age: 28,
        startWeightKg: 85.0,
        targetWeightKg: 78.0,
        heightCm: 180.0,
        activityLevel: ActivityLevel.moderate,
        goal: WeightGoal.reduction,
        dailyCaloriesGoal: 2000,
        proteinGoalGrams: 150,
        carbsGoalGrams: 200,
        fatGoalGrams: 60,
        waterGoalMl: 2500,
      );

      // Log 1800 kcal (meets reduction target of 2000+100) for today, yesterday, and 2 days ago
      for (int i = 0; i < 3; i++) {
        final date = today.subtract(Duration(days: i));
        final dk = DateFormatter.toDateKey(date);
        await diaryRepo.addEntry(
          dateKey: dk,
          mealType: MealType.dinner,
          product: dummyProduct,
          grams: 900.0, // 900g * 2 kcal/g = 1800 kcal
        );
      }

      final streakInfo = service.calculateStreak(
        diaryRepo: diaryRepo,
        profile: profile,
      );

      expect(streakInfo.currentStreak, 3);
      expect(streakInfo.bestStreak, greaterThanOrEqualTo(3));
      expect(streakInfo.isTodayAchieved, isTrue);
      expect(streakInfo.headline, contains('3 dni z rzędu w deficycie'));
    });
  });

  group('GamificationService - Weight Forecast & MacroFactor model', () {
    test('calculates accurate reduction forecast date and weekly pace', () {
      const profile = UserProfile(
        gender: Gender.male,
        age: 30,
        startWeightKg: 85.0,
        targetWeightKg: 80.0, // 5 kg to lose
        heightCm: 180.0,
        activityLevel: ActivityLevel.moderate, // 1.55 multiplier
        goal: WeightGoal.reduction,
        dailyCaloriesGoal: 2200,
        proteinGoalGrams: 160,
        carbsGoalGrams: 220,
        fatGoalGrams: 70,
        waterGoalMl: 2500,
      );

      final forecast = service.calculateForecast(
        profile: profile,
        weightRepo: weightRepo,
        diaryRepo: diaryRepo,
      );

      expect(forecast.currentWeightKg, 85.0);
      expect(forecast.targetWeightKg, 80.0);
      expect(forecast.goal, WeightGoal.reduction);
      expect(forecast.dailyDeficitOrSurplusKcal, lessThan(0)); // In deficit
      expect(forecast.weeklyPaceKg, greaterThan(0));
      expect(forecast.daysToGoal, isNotNull);
      expect(forecast.estimatedDate, isNotNull);
      expect(forecast.headline, contains('80.0 kg'));
      expect(forecast.trajectory.isNotEmpty, isTrue);
    });
  });

  group('GamificationService - Achievement Evaluation', () {
    test('evaluates locked and unlocked badges correctly based on recorded progress', () {
      const profile = UserProfile(
        gender: Gender.female,
        age: 26,
        startWeightKg: 65.0,
        targetWeightKg: 60.0,
        heightCm: 168.0,
        activityLevel: ActivityLevel.light,
        goal: WeightGoal.reduction,
        dailyCaloriesGoal: 1600,
        proteinGoalGrams: 120,
        carbsGoalGrams: 160,
        fatGoalGrams: 50,
        waterGoalMl: 2000,
      );

      final streakInfo = service.calculateStreak(
        diaryRepo: diaryRepo,
        profile: profile,
      );

      final badges = service.evaluateAchievements(
        diaryRepo: diaryRepo,
        waterRepo: waterRepo,
        weightRepo: weightRepo,
        profile: profile,
        streakInfo: streakInfo,
      );

      expect(badges.length, greaterThanOrEqualTo(10));
      expect(badges.any((b) => b.id == 'streak_3'), isTrue);
      expect(badges.any((b) => b.id == 'water_7'), isTrue);
      expect(badges.any((b) => b.id == 'protein_monster'), isTrue);
    });
  });
}
