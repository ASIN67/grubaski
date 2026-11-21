import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/providers/diary_provider.dart';
import 'package:grubasek/repositories/diary_repository.dart';
import 'package:grubasek/screens/diary_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/date_formatter.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory hiveDirectory;
  late DiaryRepository repository;
  const product = FoodProduct(
    id: 'oatmeal',
    name: 'Owsianka testowa',
    caloriesPer100g: 200,
    proteinPer100g: 12,
    carbsPer100g: 35,
    fatPer100g: 4,
  );

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('grubasek_diary_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(FoodProductAdapter());
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(MealEntryAdapter());
    Hive.registerAdapter(DailyWaterLogAdapter());
    await Hive.openBox<UserProfile>(HiveService.userProfileBoxName);
    await Hive.openBox<MealEntry>(HiveService.mealEntriesBoxName);
    await Hive.openBox<DailyWaterLog>(HiveService.waterLogsBoxName);
    repository = DiaryRepository();
  });

  setUp(() async {
    await HiveService.instance.mealEntriesBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('editing a diary row updates its original Hive entry',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final date = DateTime.now();
    final original = await tester.runAsync(
      () => repository.addEntry(
        dateKey: DateFormatter.toDateKey(date),
        mealType: MealType.breakfast,
        product: product,
        grams: 125.5,
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DiaryScreen())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(product.name));
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    expect(tester.widget<TextField>(input).controller!.text, '125,5');
    await tester.enterText(input, '150,5');
    await tester.pump();
    expect(find.text('301 kcal'), findsOneWidget);

    final saveButton = find.text('Zapisz zmiany');
    await tester.ensureVisible(saveButton);
    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await HiveService.instance.mealEntriesBox.flush();
    });
    await tester.pumpAndSettle();

    final entries = repository.getEntriesForDate(date);
    expect(entries, hasLength(1));
    expect(entries.single.id, original!.id);
    expect(entries.single.grams, 150.5);
    expect(find.text('150,5 g'), findsOneWidget);
  });

  test('copying a meal appends only its entries and refreshes the active day',
      () async {
    final container = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final diary = container.read(diaryProvider.notifier);
    final today = container.read(diaryProvider).selectedDate;
    final yesterday = DateUtils.addDaysToDate(today, -1);
    final tomorrow = DateUtils.addDaysToDate(today, 1);

    final original = await diary.addEntry(
      mealType: MealType.lunch,
      product: product,
      grams: 75,
      date: yesterday,
    );
    await diary.addEntry(
      mealType: MealType.breakfast,
      product: product,
      grams: 100,
      date: yesterday,
    );
    final existing = await diary.addEntry(
      mealType: MealType.lunch,
      product: product,
      grams: 50,
    );

    final copies = await diary.copyMeal(
      sourceDate: yesterday,
      sourceMealType: MealType.lunch,
      targetDate: today,
      targetMealType: MealType.lunch,
    );
    expect(copies, hasLength(1));
    expect(copies.single.id, isNot(original.id));
    expect(copies.single.grams, 75);
    final todayState = container.read(diaryProvider);
    expect(todayState.totalCalories, 250);
    expect(todayState.entries.map((entry) => entry.id), contains(existing.id));

    final movedCopies = await diary.copyMeal(
      sourceDate: today,
      sourceMealType: MealType.lunch,
      targetDate: tomorrow,
      targetMealType: MealType.dinner,
    );
    expect(movedCopies, hasLength(2));
    expect(
        repository.getEntriesForDate(tomorrow).map((entry) => entry.mealType),
        everyElement(MealType.dinner));
    expect(container.read(diaryProvider).totalCalories, 250);
  });
}
