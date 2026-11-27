import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/ai_meal_models.dart';
import 'package:grubasek/services/ai_meal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;

class MockAdapter implements HttpClientAdapter {
  final Map<String, dynamic> responseData;
  final int statusCode;

  MockAdapter({required this.responseData, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseData),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AiMealModels Tests', () {
    test('fromJson and toJson parses complete estimation correctly', () {
      final json = {
        'mealName': 'Jajecznica z 3 jaj z chlebem',
        'calories': 420.0,
        'proteinGrams': 22.5,
        'carbsGrams': 28.0,
        'fatGrams': 24.0,
        'estimatedWeightGrams': 250.0,
        'confidence': 'Wysoka',
        'adviceOrNotes': 'Zbilansowany posiłek białkowo-tłuszczowy.',
        'ingredients': [
          {
            'name': 'Jajka kurze',
            'weightGrams': 160.0,
            'calories': 220.0,
            'protein': 20.0,
            'carbs': 1.0,
            'fat': 15.0,
          },
          {
            'name': 'Chleb żytni',
            'weightGrams': 70.0,
            'calories': 160.0,
            'protein': 2.5,
            'carbs': 27.0,
            'fat': 1.0,
          },
        ],
      };

      final result = AiMealEstimationResult.fromJson(json);

      expect(result.mealName, 'Jajecznica z 3 jaj z chlebem');
      expect(result.calories, 420.0);
      expect(result.proteinGrams, 22.5);
      expect(result.carbsGrams, 28.0);
      expect(result.fatGrams, 24.0);
      expect(result.estimatedWeightGrams, 250.0);
      expect(result.confidence, 'Wysoka');
      expect(result.ingredients, hasLength(2));
      expect(result.ingredients.first.name, 'Jajka kurze');

      // Test conversion to FoodProduct
      final product = result.toFoodProduct();
      expect(product.name, 'Jajecznica z 3 jaj z chlebem');
      expect(product.servingSizeGrams, 250.0);
      expect(product.caloriesForGrams(250.0).round(), 420);
      expect(product.isCustom, isTrue);
    });
  });

  group('AiMealService Tests', () {
    test('estimateMeal throws ArgumentError if neither text nor image provided',
        () async {
      final service = AiMealService();
      expect(
        () => service.estimateMeal(),
        throwsArgumentError,
      );
    });

    test('estimateMeal parses Gemini response successfully for text input',
        () async {
      final geminiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'mealName': 'Owsianka z borówkami i miodem',
                    'calories': 350,
                    'proteinGrams': 14.0,
                    'carbsGrams': 58.0,
                    'fatGrams': 6.5,
                    'estimatedWeightGrams': 300,
                    'confidence': 'Wysoka',
                    'adviceOrNotes': 'Świetne źródło błonnika i energii.',
                    'ingredients': [
                      {
                        'name': 'Płatki owsiane',
                        'weightGrams': 60,
                        'calories': 225,
                        'protein': 8.0,
                        'carbs': 40.0,
                        'fat': 4.0,
                      }
                    ],
                  }),
                }
              ],
            },
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(responseData: geminiResponse);
      final service = AiMealService(dio: dio);

      final result = await service.estimateMeal(
        textPrompt: 'Miska owsianki z mlekiem, miodem i borówkami',
      );

      expect(result.mealName, 'Owsianka z borówkami i miodem');
      expect(result.calories, 350.0);
      expect(result.proteinGrams, 14.0);
      expect(result.ingredients, hasLength(1));
    });

    test('estimateMeal cleans markdown code fences in response', () async {
      final geminiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': '```json\n{\n  "mealName": "Sałatka Cezar",\n  "calories": 480,\n  "proteinGrams": 32.0,\n  "carbsGrams": 18.0,\n  "fatGrams": 24.0,\n  "estimatedWeightGrams": 280\n}\n```',
                }
              ],
            },
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(responseData: geminiResponse);
      final service = AiMealService(dio: dio);

      final result = await service.estimateMeal(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(result.mealName, 'Sałatka Cezar');
      expect(result.calories, 480.0);
      expect(result.proteinGrams, 32.0);
    });

    test('failover instantly on 429 to succeed with next key or model', () async {
      var callCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = _FailoverAdapter(
        onFetch: (options) {
          callCount++;
          if (callCount == 1) {
            // First call fails with 429 Rate limit
            return ResponseBody.fromString(
              jsonEncode({'error': {'code': 429, 'message': 'ResourceExhausted'}}),
              429,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          // Second call succeeds
          return ResponseBody.fromString(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'mealName': 'Kanapka z twarogiem',
                          'calories': 250,
                          'proteinGrams': 18.0,
                          'carbsGrams': 30.0,
                          'fatGrams': 5.0,
                          'estimatedWeightGrams': 150,
                          'confidence': 'Wysoka',
                          'adviceOrNotes': 'Lekki i pożywny posiłek.',
                          'ingredients': []
                        })
                      }
                    ]
                  }
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        },
      );

      final service = AiMealService(dio: dio);
      final result = await service.estimateMeal(textPrompt: 'Kanapka z twarogiem');
      expect(result.mealName, 'Kanapka z twarogiem');
      expect(callCount, greaterThanOrEqualTo(2));
    });

    test('suggestMealsForRemainingMacro parses suggestions correctly', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapter(responseData: {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'suggestions': [
                      {
                        'title': 'Szejk białkowy z bananem',
                        'description': 'Zblenduj białko z mlekiem i bananem',
                        'prepTimeMinutes': 5,
                        'calories': 320,
                        'protein': 30.0,
                        'carbs': 35.0,
                        'fat': 4.0,
                        'ingredients': ['30g odżywki', '1 banan', '250ml mleka']
                      }
                    ]
                  })
                }
              ]
            }
          }
        ]
      });

      final service = AiMealService(dio: dio);
      final suggestions = await service.suggestMealsForRemainingMacro(
        remainingCalories: 320,
        remainingProtein: 30,
        remainingCarbs: 35,
        remainingFat: 4,
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.first.title, 'Szejk białkowy z bananem');
      expect(suggestions.first.prepTimeMinutes, 5);
      expect(suggestions.first.calories, 320);
    });

    test(
        'awaits syncKeysFromSupabase before first request when called immediately without init()',
        () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _FailoverAdapter(
        onFetch: (options) {
          requestedUrls.add(options.uri.toString());
          return _validEstimationResponse('Jabłko');
        },
      );

      final fakeClient = _FakeSupabaseClient(
        onQueryKeys: () async => [
          {'api_key': 'supa_key_1'},
          {'api_key': 'supa_key_2'},
        ],
      );

      final service = AiMealService(
        dio: dio,
        supabaseClientProvider: () => fakeClient,
      );
      expect(service.hasSyncedKeys, isFalse);

      final result = await service.estimateMeal(textPrompt: 'Jabłko');

      expect(result.mealName, 'Jabłko');
      expect(service.hasSyncedKeys, isTrue);
      expect(service.activeKeys, equals(['supa_key_1', 'supa_key_2']));
      expect(fakeClient.queryCount, equals(1));
      expect(requestedUrls.single, contains('key=supa_key_1'));
    });

    test(
        'joins in-flight init() sync instead of racing with fallback key and supports 429 failover across synced keys',
        () async {
      final gate = Completer<List<Map<String, dynamic>>>();
      final requestedKeys = <String>[];

      final dio = Dio();
      dio.httpClientAdapter = _FailoverAdapter(
        onFetch: (options) {
          final key = options.uri.queryParameters['key'] ?? '';
          requestedKeys.add(key);
          if (key == 'delayed_key_1') {
            return ResponseBody.fromString(
              jsonEncode({'error': {'code': 429, 'message': 'Quota'}}),
              429,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return _validEstimationResponse('Banan');
        },
      );

      final fakeClient = _FakeSupabaseClient(
        onQueryKeys: () => gate.future,
      );

      final service = AiMealService(
        dio: dio,
        supabaseClientProvider: () => fakeClient,
      );

      // Mimic aiMealServiceProvider calling init() without awaiting
      final initFuture = service.init();
      // Immediate AI call before init() finishes
      final estimateFuture = service.estimateMeal(textPrompt: 'Banan');

      expect(requestedKeys, isEmpty);

      gate.complete([
        {'api_key': 'delayed_key_1'},
        {'api_key': 'delayed_key_2'},
      ]);

      final result = await estimateFuture;
      await initFuture;

      expect(result.mealName, 'Banan');
      expect(fakeClient.queryCount, equals(1));
      expect(service.hasSyncedKeys, isTrue);
      expect(requestedKeys, equals(['delayed_key_1', 'delayed_key_2']));

      // Subsequent call does not re-query Supabase
      await service.estimateMeal(textPrompt: 'Banan');
      expect(fakeClient.queryCount, equals(1));
    });

    test('handles null Supabase client and sync errors gracefully without throwing',
        () async {
      final dio = Dio();
      dio.httpClientAdapter = _FailoverAdapter(
        onFetch: (_) => _validEstimationResponse('Gruszka'),
      );

      final offlineService = AiMealService(
        dio: dio,
        supabaseClientProvider: () => null,
      );
      final offlineResult = await offlineService.estimateMeal(textPrompt: 'Gruszka');
      expect(offlineResult.mealName, 'Gruszka');
      expect(offlineService.hasSyncedKeys, isFalse);

      final failingClient = _FakeSupabaseClient(
        onQueryKeys: () async => throw Exception('Supabase unreachable'),
      );
      final errorService = AiMealService(
        dio: dio,
        supabaseClientProvider: () => failingClient,
      );
      final errorResult = await errorService.estimateMeal(textPrompt: 'Gruszka');
      expect(errorResult.mealName, 'Gruszka');
      expect(errorService.hasSyncedKeys, isFalse);
    });
  });
}

ResponseBody _validEstimationResponse(String mealName) {
  return ResponseBody.fromString(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': jsonEncode({
                  'mealName': mealName,
                  'calories': 100,
                  'proteinGrams': 1.0,
                  'carbsGrams': 24.0,
                  'fatGrams': 0.5,
                  'estimatedWeightGrams': 180,
                  'confidence': 'Wysoka',
                  'adviceOrNotes': 'OK',
                  'ingredients': [],
                }),
              }
            ],
          },
        }
      ],
    }),
    200,
    headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
  );
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  final Future<List<Map<String, dynamic>>> Function() onQueryKeys;
  int queryCount = 0;

  _FakeSupabaseClient({required this.onQueryKeys});

  @override
  SupabaseQueryBuilder from(String table) {
    return _FakeAiKeysQueryBuilder(
      onExecute: () {
        queryCount++;
        return onQueryKeys();
      },
    );
  }
}

class _FakeAiKeysQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Future<List<Map<String, dynamic>>> Function() onExecute;

  _FakeAiKeysQueryBuilder({required this.onExecute});

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeAiKeysFilterBuilder(onExecute: onExecute);
  }
}

class _FakeAiKeysFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final Future<List<Map<String, dynamic>>> Function() onExecute;

  _FakeAiKeysFilterBuilder({required this.onExecute});

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return _FakeAiKeysTransformBuilder(onExecute: onExecute);
  }
}

class _FakeAiKeysTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  final Future<List<Map<String, dynamic>>> Function() onExecute;

  _FakeAiKeysTransformBuilder({required this.onExecute});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return onExecute().then(onValue, onError: onError);
  }

  @override
  Future<PostgrestList> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return onExecute().catchError(onError, test: test);
  }

  @override
  Future<PostgrestList> whenComplete(FutureOr<void> Function() action) {
    return onExecute().whenComplete(action);
  }

  @override
  Future<PostgrestList> timeout(
    Duration timeLimit, {
    FutureOr<PostgrestList> Function()? onTimeout,
  }) {
    return onExecute().timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Stream<PostgrestList> asStream() => onExecute().asStream();
}

class _FailoverAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) onFetch;
  _FailoverAdapter({required this.onFetch});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}
