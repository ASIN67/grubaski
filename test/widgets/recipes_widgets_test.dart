import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/providers/diary_provider.dart';
import 'package:grubasek/providers/user_profile_provider.dart';
import 'package:grubasek/repositories/diary_repository.dart';
import 'package:grubasek/repositories/user_repository.dart';
import 'package:grubasek/screens/recipes_screen.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:grubasek/widgets/adaptive_coach_view.dart';
import 'package:grubasek/widgets/ai_macro_finisher_sheet.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  FakeUserProfileNotifier(UserProfile initial) : super(UserRepository()) {
    state = initial;
  }
}

void main() {
  late Directory tempDir;
  late DiaryRepository diaryRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('recipes_widgets_test_');
    await HiveService.instance.init(customPath: tempDir.path);
    diaryRepo = DiaryRepository(hiveService: HiveService.instance);
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('RecipesScreen Widget Tests', () {
    testWidgets('renders search field, category chips and action button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecipesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Szukaj przepisów, składników...'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Wszystkie'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Śniadanie'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Obiad'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('AdaptiveCoachView Widget Tests', () {
    testWidgets('renders dynamic TDEE and recommendation view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));

      const testProfile = UserProfile(
        age: 26,
        gender: Gender.male,
        heightCm: 180,
        startWeightKg: 85.0,
        targetWeightKg: 78.0,
        activityLevel: ActivityLevel.moderate,
        goal: WeightGoal.reduction,
        weeklyPaceKg: 0.5,
        dailyCaloriesGoal: 2200,
        proteinGoalGrams: 165,
        carbsGoalGrams: 220,
        fatGoalGrams: 73,
        waterGoalMl: 2500,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier(testProfile)),
            diaryRepositoryProvider.overrideWithValue(diaryRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdaptiveCoachView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Adaptacyjny Coach Kalorii'), findsOneWidget);
      expect(find.text('Twój rzeczywisty metabolizm (TDEE):'), findsOneWidget);
      expect(find.text('Zalecenie na kolejny tydzień'), findsOneWidget);
      expect(find.textContaining('Zastosuj zalecany cel'), findsOneWidget);
    });
  });

  group('AiMacroFinisherSheet Widget Tests', () {
    testWidgets('renders remaining macro targets header and badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AiMacroFinisherSheet.show(
                        context,
                        remainingCalories: 450,
                        remainingProtein: 35.0,
                        remainingCarbs: 40.0,
                        remainingFat: 15.0,
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Dokończ moje makro (AI)'), findsOneWidget);
      expect(find.textContaining('450 kcal'), findsOneWidget);
      expect(find.textContaining('35.0g'), findsOneWidget);
      expect(find.textContaining('40.0g'), findsOneWidget);
      expect(find.textContaining('15.0g'), findsOneWidget);
    });
  });
}
