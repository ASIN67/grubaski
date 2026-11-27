import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/providers/diary_provider.dart';
import 'package:grubasek/providers/product_search_provider.dart';
import 'package:grubasek/screens/add_portion_sheet.dart';
import 'package:grubasek/screens/add_product_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';
import 'package:hive/hive.dart';

void main() {
  final hive = HiveService.instance;
  late Directory database;
  const oats = FoodProduct(
    id: 'oats',
    name: 'Płatki owsiane',
    caloriesPer100g: 370,
    proteinPer100g: 13,
    carbsPer100g: 60,
    fatPer100g: 7,
    fiberPer100g: 10,
  );
  const banana = FoodProduct(
    id: 'banana',
    name: 'Banan',
    caloriesPer100g: 90,
    proteinPer100g: 1,
    carbsPer100g: 23,
    fatPer100g: 0,
  );

  setUpAll(() async {
    database = await Directory.systemTemp.createTemp('grubasek_catalog_');
    Hive.init(database.path);
    Hive.registerAdapter(FoodProductAdapter());
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(MealEntryAdapter());
    Hive.registerAdapter(RecipeIngredientAdapter());
    await Hive.openBox<FoodProduct>(HiveService.foodProductsBoxName);
    await Hive.openBox<MealEntry>(HiveService.mealEntriesBoxName);
  });

  setUp(() async {
    await hive.mealEntriesBox.clear();
    await hive.foodProductsBox.clear();
    await hive.foodProductsBox.putAll({oats.id: oats, banana.id: banana});
  });

  tearDownAll(() async {
    await Hive.close();
    await database.delete(recursive: true);
  });

  Future<void> mountCatalog(
      WidgetTester tester, ProviderContainer state) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: state,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [Locale('pl', 'PL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AddProductScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'quick entry saves one snapshot to the active diary and stays on catalog',
      (tester) async {
    final state = ProviderContainer();
    await mountCatalog(tester, state);
    await tester.tap(find.text('Szybki wpis'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa'), 'Kebab');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Kalorie'), '750');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Białko'), '22,5');

    final save = find.widgetWithText(FilledButton, 'Zapisz wpis');
    await tester.ensureVisible(save);
    await tester.runAsync(() async {
      await tester.tap(save);
      await hive.mealEntriesBox.flush();
    });
    await tester.pumpAndSettle();

    expect(save, findsNothing);
    expect(find.text('Dodaj do posiłku'), findsOneWidget);
    final diary = state.read(diaryProvider);
    expect(diary.totalCalories, 750);
    expect(diary.totalProtein, 22.5);
    expect(diary.entries.single.product.name, 'Kebab');
    expect(diary.entries.single.product.isQuickAdd, isTrue);
    expect(diary.entries.single.weightGrams, isNull);
  });

  testWidgets(
      'favorite changes immediately populate and clear the Favorites tab',
      (tester) async {
    await mountCatalog(tester, ProviderContainer());
    final oatsTile = find.widgetWithText(ListTile, oats.name);
    Finder star(String label) => find.descendant(
          of: oatsTile,
          matching: find.byTooltip(label),
        );

    await tester.runAsync(() async {
      await tester.tap(star('Dodaj do ulubionych'));
      await hive.foodProductsBox.flush();
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ulubione'));
    await tester.pumpAndSettle();

    expect(oatsTile, findsOneWidget);
    expect(find.text(banana.name), findsNothing);
    expect(hive.foodProductsBox.get(oats.id)!.isFavorite, isTrue);
    await tester.runAsync(() async {
      await tester.tap(star('Usuń z ulubionych'));
      await hive.foodProductsBox.flush();
    });
    await tester.pumpAndSettle();

    expect(oatsTile, findsNothing);
    expect(hive.foodProductsBox.get(oats.id)!.isFavorite, isFalse);
  });

  testWidgets(
      'recipe ingredients sum into a stored recipe and half-sized meal entry',
      (tester) async {
    final state = ProviderContainer();
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(state.dispose);

    final recipe = (await tester.runAsync(() async {
      final created = await state.read(productRepositoryProvider).createRecipe(
        name: 'Moja owsianka',
        ingredients: const [
          RecipeIngredient(product: oats, grams: 50),
          RecipeIngredient(product: banana, grams: 100),
        ],
      );
      await hive.foodProductsBox.flush();
      return created;
    }))!;

    expect(recipe.recipeIngredients, hasLength(2));
    expect(recipe.caloriesPer100g, 275);
    expect(recipe.fiberPer100g, 5);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: state,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('pl', 'PL'),
          supportedLocales: const [Locale('pl', 'PL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await AddPortionSheet.show(
                      context,
                      product: recipe,
                      initialMealType: MealType.breakfast,
                    );
                  },
                  child: const Text('Log Recipe'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Recipe'));
    await tester.pumpAndSettle();

    expect(find.text('275 kcal'), findsOneWidget);

    await tester.tap(find.text('½ porcji'));
    await tester.pumpAndSettle();
    final logPortion = find.text('Dodaj do dziennika');
    await tester.ensureVisible(logPortion);
    await tester.runAsync(() async {
      await tester.tap(logPortion);
      await hive.mealEntriesBox.flush();
    });
    await tester.pumpAndSettle();

    final entry = state.read(diaryProvider).entries.single;
    expect(entry.product.id, recipe.id);
    expect(entry.calories, 137.5);
    expect(entry.fiber, 2.5);
    expect(entry.weightGrams, 75);
  });
}
