import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/food_product.dart';
import 'package:grubasek/models/meal_entry.dart';
import 'package:grubasek/models/meal_type.dart';
import 'package:grubasek/models/user_profile.dart';
import 'package:grubasek/utils/app_colors.dart';
import 'package:grubasek/utils/app_theme.dart';
import 'package:grubasek/utils/nutrition_calculator.dart';
import 'package:grubasek/widgets/calorie_summary_card.dart';
import 'package:grubasek/widgets/daily_date_picker_bar.dart';
import 'package:grubasek/widgets/macro_progress_ring.dart';
import 'package:grubasek/widgets/meal_expansion_card.dart';
import 'package:grubasek/widgets/water_tracker_card.dart';

void main() {
  group('AppTheme & AppColors Tests', () {
    test('AppColors fitness constants are valid', () {
      expect(AppColors.calories, isA<Color>());
      expect(AppColors.protein, isA<Color>());
      expect(AppColors.carbs, isA<Color>());
      expect(AppColors.fat, isA<Color>());
      expect(AppColors.water, isA<Color>());
    });

    test('AppTheme light and dark themes are properly configured', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
    });
  });

  group('NutritionCalculator & Weekly Pace Tests', () {
    test('deduces reduction goal when target < current weight', () {
      final goal = NutritionCalculator.deduceGoal(
        currentWeightKg: 80.0,
        targetWeightKg: 72.0,
      );
      expect(goal, WeightGoal.reduction);
    });

    test('deduces surplus goal when target > current weight', () {
      final goal = NutritionCalculator.deduceGoal(
        currentWeightKg: 65.0,
        targetWeightKg: 72.0,
      );
      expect(goal, WeightGoal.surplus);
    });

    test('deduces maintenance goal when target == current weight', () {
      final goal = NutritionCalculator.deduceGoal(
        currentWeightKg: 70.0,
        targetWeightKg: 70.0,
      );
      expect(goal, WeightGoal.maintenance);
    });

    test('calculates correct daily caloric offset from weekly pace', () {
      // 0.5 kg/week deficit -> 0.5 * 1100 = 550 kcal deficit
      final offsetRed = NutritionCalculator.calculateCalorieOffset(
        goal: WeightGoal.reduction,
        weeklyPaceKg: 0.5,
      );
      expect(offsetRed, -550);

      // 0.25 kg/week deficit -> -275 kcal
      final offsetRedLight = NutritionCalculator.calculateCalorieOffset(
        goal: WeightGoal.reduction,
        weeklyPaceKg: 0.25,
      );
      expect(offsetRedLight, -275);

      // 0.35 kg/week surplus -> +385 kcal
      final offsetSurplus = NutritionCalculator.calculateCalorieOffset(
        goal: WeightGoal.surplus,
        weeklyPaceKg: 0.35,
      );
      expect(offsetSurplus, 385);

      // Maintenance -> 0
      final offsetMaint = NutritionCalculator.calculateCalorieOffset(
        goal: WeightGoal.maintenance,
        weeklyPaceKg: 0.5,
      );
      expect(offsetMaint, 0);
    });

    test('calculates estimated weeks to goal accurately', () {
      // 10 kg to lose at 0.5 kg/week -> 20 weeks
      final weeks = NutritionCalculator.calculateEstimatedWeeks(
        currentWeightKg: 80.0,
        targetWeightKg: 70.0,
        weeklyPaceKg: 0.5,
      );
      expect(weeks, 20);

      // 5 kg to lose at 0.75 kg/week -> ceil(5 / 0.75) = 7 weeks
      final weeksFast = NutritionCalculator.calculateEstimatedWeeks(
        currentWeightKg: 75.0,
        targetWeightKg: 70.0,
        weeklyPaceKg: 0.75,
      );
      expect(weeksFast, 7);
    });
  });

  group('Widget Rendering Tests', () {
    testWidgets('MacroProgressRing renders remaining calories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MacroProgressRing(
              consumedCalories: 1500,
              goalCalories: 2000,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('500'), findsOneWidget);
      expect(find.text('pozostało'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
    });

    testWidgets('MealExpansionCard inside ListView renders and expands', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                MealExpansionCard(
                  mealType: MealType.breakfast,
                  entries: const [],
                  isInitiallyExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Śniadanie'), findsOneWidget);
      expect(find.text('Dodaj produkt'), findsOneWidget);
    });

    testWidgets('CalorieSummaryCard renders macros and calories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalorieSummaryCard(
              caloriesConsumed: 1600,
              caloriesGoal: 2200,
              proteinConsumed: 120,
              proteinGoal: 150,
              carbsConsumed: 180,
              carbsGoal: 250,
              fatConsumed: 45,
              fatGoal: 65,
            ),
          ),
        ),
      );

      expect(find.text('Kalorie i makroskładniki'), findsOneWidget);
      expect(find.text('Cel: 2200 kcal'), findsOneWidget);
      expect(find.text('Białko'), findsOneWidget);
      expect(find.text('Węglowodany'), findsOneWidget);
      expect(find.text('Tłuszcze'), findsOneWidget);
    });

    testWidgets('DailyDatePickerBar shows formatted date and handles chevron navigation', (tester) async {
      DateTime? tappedDate;
      final today = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyDatePickerBar(
              selectedDate: today,
              onDateSelected: (date) {
                tappedDate = date;
              },
            ),
          ),
        ),
      );

      expect(find.text('Dzisiaj'), findsOneWidget);

      // Tap previous day
      await tester.tap(find.byTooltip('Poprzedni dzień'));
      expect(tappedDate, isNotNull);
      expect(tappedDate!.day, today.subtract(const Duration(days: 1)).day);
    });

    testWidgets('MealExpansionCard displays meal title and products', (tester) async {
      bool addPressed = false;
      const testProduct = FoodProduct(
        id: 'p1',
        name: 'Owsianka z borówkami',
        brand: 'Grubasek Kitchen',
        caloriesPer100g: 350,
        proteinPer100g: 12,
        carbsPer100g: 60,
        fatPer100g: 6,
      );
      const testEntry = MealEntry(
        id: 'e1',
        dateKey: '2026-11-21',
        mealType: MealType.breakfast,
        grams: 100,
        product: testProduct,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealExpansionCard(
              mealType: MealType.breakfast,
              entries: const [testEntry],
              onAddProduct: () {
                addPressed = true;
              },
              onDeleteEntry: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Śniadanie'), findsOneWidget);
      expect(find.text('Owsianka z borówkami'), findsOneWidget);
      expect(find.text('350 kcal'), findsWidgets);

      await tester.tap(find.text('Dodaj produkt'));
      expect(addPressed, isTrue);
    });

    testWidgets('WaterTrackerCard renders volume and reacts to quick buttons', (tester) async {
      int? deltaReceived;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaterTrackerCard(
              consumedMl: 1500,
              goalMl: 2500,
              onWaterDelta: (delta) {
                deltaReceived = delta;
              },
            ),
          ),
        ),
      );

      expect(find.text('Nawodnienie'), findsOneWidget);
      expect(find.textContaining('1500'), findsOneWidget);
      expect(find.textContaining('2500'), findsOneWidget);
      expect(find.text('Pozostało: 1000 ml'), findsOneWidget);

      await tester.tap(find.text('+250 ml'));
      expect(deltaReceived, 250);
    });
  });
}
