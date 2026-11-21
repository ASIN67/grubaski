import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/body_measurements_repository.dart';
import 'package:grubasek/screens/progress_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';
import 'package:grubasek/utils/date_formatter.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  const boxName = HiveService.bodyMeasurementsEntriesBoxName;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('body_measurements_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(FoodProductAdapter());
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(MealEntryAdapter());
    Hive.registerAdapter(BodyMeasurementsEntryAdapter());
    await Future.wait([
      Hive.openBox<UserProfile>(HiveService.userProfileBoxName),
      Hive.openBox<MealEntry>(HiveService.mealEntriesBoxName),
      Hive.openBox<WeightEntry>(HiveService.weightEntriesBoxName),
      Hive.openBox<BodyMeasurementsEntry>(boxName),
    ]);
  });

  setUp(() async {
    await Hive.box<BodyMeasurementsEntry>(boxName).clear();
    await Hive.box<MealEntry>(HiveService.mealEntriesBoxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test(
      'circumference fields persist and updating a date preserves other values',
      () async {
    final repository = BodyMeasurementsRepository();
    await repository.save(BodyMeasurementsEntry(
      date: DateTime(2026, 10, 5, 8),
      waistCm: 91.5,
      chestCm: 100,
      armCm: 34.2,
      hipsCm: 102,
      thighCm: 59,
    ));
    await repository.save(BodyMeasurementsEntry(
      date: DateTime(2026, 10, 5, 20),
      waistCm: 90.5,
    ));
    await repository.save(BodyMeasurementsEntry(
      date: DateTime(2026, 10, 12),
      thighCm: 60,
    ));

    await Hive.box<BodyMeasurementsEntry>(boxName).close();
    await Hive.openBox<BodyMeasurementsEntry>(boxName);

    final entries = repository.getEntries();
    expect(entries, hasLength(2));
    expect(entries.first.date, DateTime(2026, 10, 12));
    expect(entries.first.waistCm, isNull);
    expect(entries.first.thighCm, 60);
    final earlierEntry = entries.last;
    expect(earlierEntry.date, DateTime(2026, 10, 5));
    expect(earlierEntry.waistCm, 90.5);
    expect(earlierEntry.chestCm, 100);
    expect(earlierEntry.armCm, 34.2);
    expect(earlierEntry.hipsCm, 102);
    expect(earlierEntry.thighCm, 59);
  });

  testWidgets('saving a measurement updates the waist chart and history',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('pl', 'PL'),
        supportedLocales: const [Locale('pl', 'PL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.darkTheme,
        home: const ProgressScreen(),
      ),
    ));

    expect(find.text('Waga w czasie'), findsOneWidget);
    await tester.tap(find.text('Obwody ciała'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsNothing);

    await tester.tap(find.text('Dodaj pomiar'));
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(FilledButton, 'Zapisz');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Podaj co najmniej jeden obwód.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Pas'), '94,5');
    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await Hive.box<BodyMeasurementsEntry>(boxName).flush();
    });
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Historia pomiarów'), findsOneWidget);
    expect(find.text('Pas 94,5 cm'), findsOneWidget);
    expect(BodyMeasurementsRepository().getEntries().single.waistCm, 94.5);
  });

  testWidgets('calorie chart follows changes to an open diary box',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: ProgressScreen()),
    ));
    double todayCalories() => tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups
        .last
        .barRods
        .single
        .toY;
    expect(todayCalories(), 0);

    final entry = MealEntry(
      id: 'quick',
      dateKey: DateFormatter.toDateKey(DateTime.now()),
      mealType: MealType.lunch,
      grams: 100,
      product: const FoodProduct(
        id: 'quick',
        name: 'Lunch',
        caloriesPer100g: 750,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        isQuickAdd: true,
      ),
    );
    await tester.runAsync(() async {
      await HiveService.instance.mealEntriesBox.put(entry.id, entry);
    });
    await tester.pumpAndSettle();

    expect(todayCalories(), 750);
  });
}
