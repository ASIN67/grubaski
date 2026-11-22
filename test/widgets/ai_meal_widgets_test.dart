import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/providers/ai_meal_provider.dart';
import 'package:grubasek/providers/diary_provider.dart';
import 'package:grubasek/repositories/diary_repository.dart';
import 'package:grubasek/screens/ai_meal_estimation_screen.dart';
import 'package:grubasek/services/ai_meal_service.dart';
import 'package:grubasek/services/hive_service.dart';

class MockDioAdapter implements HttpClientAdapter {
  final Map<String, dynamic> responseData;
  MockDioAdapter(this.responseData);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late DiaryRepository diaryRepo;

  final sampleEstimationResponse = {
    'candidates': [
      {
        'content': {
          'parts': [
            {
              'text': jsonEncode({
                'mealName': 'Spaghetti Bolognese',
                'calories': 620,
                'proteinGrams': 34.0,
                'carbsGrams': 75.0,
                'fatGrams': 18.0,
                'estimatedWeightGrams': 420,
                'confidence': 'Wysoka',
                'adviceOrNotes': 'Bogate w białko i węglowodany złożone.',
                'ingredients': [
                  {
                    'name': 'Makaron spaghetti',
                    'weightGrams': 120,
                    'calories': 250,
                    'protein': 9.0,
                    'carbs': 52.0,
                    'fat': 1.5,
                  },
                  {
                    'name': 'Sos mięsno-pomidorowy',
                    'weightGrams': 300,
                    'calories': 370,
                    'protein': 25.0,
                    'carbs': 23.0,
                    'fat': 16.5,
                  }
                ],
              }),
            }
          ],
        },
      }
    ]
  };

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ai_meal_test_');
    await HiveService.instance.init(customPath: tempDir.path);
    diaryRepo = DiaryRepository(hiveService: HiveService.instance);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('AiMealEstimationScreen renders input fields, camera & gallery buttons',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dio = Dio();
    dio.httpClientAdapter = MockDioAdapter(sampleEstimationResponse);
    final service = AiMealService(dio: dio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiMealServiceProvider.overrideWithValue(service),
          diaryRepositoryProvider.overrideWithValue(diaryRepo),
        ],
        child: MaterialApp(
          home: AiMealEstimationScreen(
            initialMealType: MealType.dinner,
            initialDate: DateTime.now(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oszacuj Makro AI'), findsOneWidget);
    expect(find.text('Zrób zdjęcie'), findsOneWidget);
    expect(find.text('Z galerii'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('✨ Oblicz makro z opisu'), findsOneWidget);
  });

  testWidgets(
      'AiMealEstimationScreen analyzes text prompt, displays results and saves to diary',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dio = Dio();
    dio.httpClientAdapter = MockDioAdapter(sampleEstimationResponse);
    final service = AiMealService(dio: dio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiMealServiceProvider.overrideWithValue(service),
          diaryRepositoryProvider.overrideWithValue(diaryRepo),
        ],
        child: MaterialApp(
          home: AiMealEstimationScreen(
            initialMealType: MealType.lunch,
            initialDate: DateTime.now(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type prompt
    final promptInput = find.byType(TextField).first;
    await tester.enterText(promptInput, 'Duży talerz spaghetti bolognese');
    await tester.pump();

    // Tap analyze button
    final analyzeBtn = find.text('✨ Oblicz makro z opisu');
    await tester.tap(analyzeBtn);
    await tester.pumpAndSettle();

    // Results card should now appear
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text('620 kcal'), findsOneWidget);
    expect(find.text('420 g'), findsOneWidget);
    expect(find.text('34.0 g'), findsOneWidget); // Protein
    expect(find.text('75.0 g'), findsOneWidget); // Carbs
    expect(find.text('18.0 g'), findsOneWidget); // Fat
    expect(find.text('Pewność: Wysoka'), findsOneWidget);
    expect(find.text('Rozpoznane składniki:'), findsOneWidget);
    expect(find.text('Makaron spaghetti'), findsOneWidget);

    // Save to diary button
    final saveButton = find.text('Dodaj do: Obiad');
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await HiveService.instance.mealEntriesBox.flush();
    });
    await tester.pumpAndSettle();

    // Check that entry is in diary
    final date = DateTime.now();
    final entries = diaryRepo.getEntriesForDate(date);
    expect(entries.any((e) => e.product.name == 'Spaghetti Bolognese'), isTrue);
  });
}
