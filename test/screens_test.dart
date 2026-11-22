import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/screens/add_portion_sheet.dart';
import 'package:grubasek/screens/create_custom_product_screen.dart';
import 'package:grubasek/screens/diary_screen.dart';
import 'package:grubasek/screens/main_navigation_screen.dart';
import 'package:grubasek/screens/onboarding_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FoodProductAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MealTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MealEntryAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(DailyWaterLogAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WeightEntryAdapter());
    await Hive.openBox<UserProfile>(HiveService.userProfileBoxName);
    await Hive.openBox<FoodProduct>(HiveService.foodProductsBoxName);
    await Hive.openBox<MealEntry>(HiveService.mealEntriesBoxName);
    await Hive.openBox<DailyWaterLog>(HiveService.waterLogsBoxName);
    await Hive.openBox<WeightEntry>(HiveService.weightEntriesBoxName);
  });

  group('Screens Rendering Tests', () {
    testWidgets('CreateCustomProductScreen renders required fields and preview',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateCustomProductScreen(
            initialBarcode: '5901234567890',
          ),
        ),
      );

      expect(find.text('Dodaj własny produkt'), findsOneWidget);
      expect(find.text('Nazwa produktu *'), findsOneWidget);
      expect(find.text('5901234567890'), findsOneWidget);
      expect(find.text('Kalorie (kcal) *'), findsOneWidget);
      expect(find.text('Białko *'), findsOneWidget);
      expect(find.text('Węglowodany *'), findsOneWidget);
      expect(find.text('Tłuszcze *'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Zapisz produkt'), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders initial step with gender and age',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.text('Witaj w Grubasku!'), findsOneWidget);
      expect(find.text('Mężczyzna'), findsOneWidget);
      expect(find.text('Kobieta'), findsOneWidget);
      expect(find.text('Dalej'), findsOneWidget);
    });

    testWidgets('AddPortionSheet displays portion controls and macros',
        (tester) async {
      const testProduct = FoodProduct(
        id: 'test-1',
        name: 'Banan świeży',
        brand: 'Chiquita',
        caloriesPer100g: 89,
        proteinPer100g: 1.1,
        carbsPer100g: 22.8,
        fatPer100g: 0.3,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddPortionSheet(
                product: testProduct,
                initialMealType: MealType.breakfast,
                initialGrams: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Banan świeży'), findsOneWidget);
      expect(find.text('Chiquita'), findsOneWidget);
      expect(find.text('Śniadanie'), findsOneWidget);
      expect(find.text('89 kcal'), findsOneWidget);
      expect(find.text('Dodaj do dziennika'), findsOneWidget);
    });
    testWidgets('DiaryScreen renders without crash and displays meals', (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DiaryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dziennik'), findsOneWidget);
      expect(find.text('Posiłki'), findsOneWidget);
      expect(find.text('Śniadanie'), findsOneWidget);
      expect(find.text('Obiad'), findsOneWidget);
      expect(find.text('Kolacja'), findsOneWidget);
    });

    testWidgets('MainNavigationScreen renders all tabs and bottom bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dziennik'), findsWidgets);
      expect(find.text('Dodaj / Skanuj'), findsOneWidget);
      expect(find.text('Postępy'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Śniadanie'), findsWidgets);
    });
  });
}
