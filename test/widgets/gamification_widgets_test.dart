import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/user_repository.dart';
import 'package:grubasek/screens/diary_screen.dart';
import 'package:grubasek/screens/progress_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/widgets/achievements_view.dart';
import 'package:grubasek/widgets/streak_banner_widget.dart';
import 'package:grubasek/widgets/weight_forecast_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveService hiveService;

  const testProfile = UserProfile(
    gender: Gender.male,
    age: 28,
    startWeightKg: 84.0,
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

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('gamification_widgets_test_');
    hiveService = HiveService.instance;
    await hiveService.init(customPath: tempDir.path);
    await UserRepository(hiveService: hiveService).saveUserProfile(testProfile);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget createTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('pl', 'PL'),
        supportedLocales: const [Locale('pl', 'PL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('StreakBannerWidget renders flame, headline, and rules explanation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const StreakBannerWidget()));
    await tester.pumpAndSettle();

    expect(find.byType(StreakBannerWidget), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(find.textContaining('deficycie'), findsOneWidget);
    expect(find.textContaining('+100 kcal marginesu'), findsOneWidget);
  });

  testWidgets('WeightForecastCard renders forecast headline, metrics and target weight', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const WeightForecastCard()));
    await tester.pumpAndSettle();

    expect(find.byType(WeightForecastCard), findsOneWidget);
    expect(find.text('Prognoza celu wagi'), findsOneWidget);
    expect(find.textContaining('78.0 kg'), findsWidgets);
    expect(find.text('Tygodniowe tempo'), findsOneWidget);
  });

  testWidgets('AchievementsView renders streak hero card, forecast and badge chips', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const AchievementsView()));
    await tester.pumpAndSettle();

    expect(find.text('Odznaki i Osiągnięcia'), findsOneWidget);
    expect(find.text('Wszystkie'), findsOneWidget);
    expect(find.text('Nawodnienie'), findsOneWidget);
    expect(find.text('Białkowy Potwór'), findsOneWidget);
    expect(find.text('Iskra Nawyków'), findsOneWidget);
  });

  testWidgets('DiaryScreen renders StreakBannerWidget seamlessly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const DiaryScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(StreakBannerWidget), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
  });

  testWidgets('ProgressScreen includes Odznaki segment and renders AchievementsView upon selection', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const ProgressScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Waga'), findsOneWidget);
    expect(find.text('Obwody ciała'), findsOneWidget);
    expect(find.text('Odznaki'), findsOneWidget);

    // Tap on 'Odznaki'
    await tester.tap(find.text('Odznaki'));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementsView), findsOneWidget);
    expect(find.text('Odznaki i Osiągnięcia'), findsOneWidget);
  });
}
