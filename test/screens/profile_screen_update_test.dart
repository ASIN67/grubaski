import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/screens/profile_screen.dart';
import 'package:grubasek/services/app_update_service.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/utils/app_theme.dart';
import 'package:grubasek/widgets/update_prompt_dialog.dart';

class FakeAppUpdateService extends AppUpdateService {
  final UpdateCheckResult mockResult;

  FakeAppUpdateService(this.mockResult);

  @override
  Future<UpdateCheckResult> checkForUpdate({
    String? currentVersionOverride,
    int? currentBuildOverride,
  }) async {
    return mockResult;
  }
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_profile_test_');
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

  group('ProfileScreen Update Section Tests', () {
    testWidgets('renders updates card and shows up-to-date snackbar when tapped',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const upToDateResult = UpdateCheckResult(
        hasUpdate: false,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      final fakeService = FakeAppUpdateService(upToDateResult);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the update section
      expect(find.text('Aktualizacje aplikacji'), findsOneWidget);
      expect(find.text('Sprawdź dostępność aktualizacji'), findsOneWidget);

      // Tap the check update button
      await tester.tap(find.text('Sprawdź dostępność aktualizacji'));
      await tester.pumpAndSettle();

      // Expect up to date snackbar
      expect(find.textContaining('Aplikacja jest aktualna'), findsOneWidget);
    });

    testWidgets('opens UpdatePromptDialog when newer update is available',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final availableRelease = AppReleaseInfo(
        id: 'rel-99',
        version: '1.5.0',
        buildNumber: 15,
        releaseNotes: 'Nowe funkcje: Synchronizacja i PWA',
        downloadUrl: 'https://grubasek.pages.dev/download/grubasek.apk',
        isMandatory: false,
        publishedAt: DateTime(2026, 11, 21),
      );

      final hasUpdateResult = UpdateCheckResult(
        hasUpdate: true,
        latestRelease: availableRelease,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      final fakeService = FakeAppUpdateService(hasUpdateResult);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap update check button
      await tester.tap(find.text('Sprawdź dostępność aktualizacji'));
      await tester.pumpAndSettle();

      // UpdatePromptDialog should appear
      expect(find.byType(UpdatePromptDialog), findsOneWidget);
      expect(find.text('Nowa wersja!'), findsOneWidget);
      expect(find.text('v1.5.0'), findsOneWidget);
      expect(find.textContaining('Nowe funkcje: Synchronizacja i PWA'), findsOneWidget);
    });
  });
}
