import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/screens/add_product_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('add_product_test_');
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
    await Hive.openBox(HiveService.settingsBoxName);
  });

  testWidgets('Debug AddProductScreen null checks in Dark Theme', (tester) async {
    final originalOnError = FlutterError.onError;
    final caughtErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      caughtErrors.add(details);
      // ignore: avoid_print
      print('FLUTTER_ERROR_CAUGHT: ${details.exception}');
      // ignore: avoid_print
      print('STACK_TRACE_CAUGHT:\n${details.stack}');
    };

    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: AddProductScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (caughtErrors.isNotEmpty) {
      fail('Caught ${caughtErrors.length} errors: ${caughtErrors.first.exception}');
    }
  });
}
