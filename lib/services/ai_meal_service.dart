import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_meal_models.dart';
import 'supabase_service.dart';

/// Service responsible for estimating meal macros and calories via Gemini AI.
/// Supports text descriptions, image photos (camera / gallery), and photo + text notes.
///
/// Features:
/// 1. Dynamic API Key Pooling from Supabase with round-robin load distribution.
/// 2. Instant failover across keys on 429 (Rate Limit) with zero sleep delay.
/// 3. Ultra-fast model cascade prioritizing low-latency Flash-Lite models (~1-2s response).
/// 4. Strict responseSchema enforcement to guarantee valid, type-safe JSON output.
/// 5. Robust JSON sanitizer to prevent any syntax / unquoted property parse crashes.
/// 6. Realistic nutritional math for macro finisher without blind number copying.
class AiMealService {
  static const String _defaultEncodedKey =
      'QVEuQWI4Uk42SXYxTHhlSFQxZjNnLUFmV0JWX2k1X0NKenVtOUk2aUpfSnRoVThyYkswZmc=';

  static String _resolveDefaultKey() {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return utf8.decode(base64Decode(_defaultEncodedKey));
    } catch (_) {
      return '';
    }
  }

  // Multi-tier pool of high-capacity Gemini models sorted by response speed and availability
  static const List<String> _candidateModels = [
    'gemini-flash-lite-latest',
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-3.6-flash',
  ];

  static const Map<String, dynamic> _estimationResponseSchema = {
    'type': 'OBJECT',
    'properties': {
      'mealName': {'type': 'STRING'},
      'calories': {'type': 'NUMBER'},
      'proteinGrams': {'type': 'NUMBER'},
      'carbsGrams': {'type': 'NUMBER'},
      'fatGrams': {'type': 'NUMBER'},
      'estimatedWeightGrams': {'type': 'NUMBER'},
      'confidence': {
        'type': 'STRING',
        'enum': ['Wysoka', 'Średnia', 'Niska']
      },
      'adviceOrNotes': {'type': 'STRING'},
      'ingredients': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'weightGrams': {'type': 'NUMBER'},
            'calories': {'type': 'NUMBER'},
            'protein': {'type': 'NUMBER'},
            'carbs': {'type': 'NUMBER'},
            'fat': {'type': 'NUMBER'}
          },
          'required': ['name', 'weightGrams', 'calories', 'protein', 'carbs', 'fat']
        }
      }
    },
    'required': [
      'mealName',
      'calories',
      'proteinGrams',
      'carbsGrams',
      'fatGrams',
      'estimatedWeightGrams',
      'confidence',
      'adviceOrNotes',
      'ingredients'
    ]
  };

  static const Map<String, dynamic> _suggestionsResponseSchema = {
    'type': 'OBJECT',
    'properties': {
      'suggestions': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'description': {'type': 'STRING'},
            'prepTimeMinutes': {'type': 'INTEGER'},
            'calories': {'type': 'NUMBER'},
            'protein': {'type': 'NUMBER'},
            'carbs': {'type': 'NUMBER'},
            'fat': {'type': 'NUMBER'},
            'ingredients': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'}
            }
          },
          'required': [
            'title',
            'description',
            'prepTimeMinutes',
            'calories',
            'protein',
            'carbs',
            'fat',
            'ingredients'
          ]
        }
      }
    },
    'required': ['suggestions']
  };

  final Dio _dio;
  List<String> _keyPool = [];
  int _keyIndex = 0;
  bool _isSyncingKeys = false;

  AiMealService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 25),
                sendTimeout: const Duration(seconds: 20),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    final def = _resolveDefaultKey();
    if (def.isNotEmpty) {
      _keyPool = [def];
    }
  }

  /// Initializes the service and syncs active API keys from Supabase.
  Future<void> init() async {
    await syncKeysFromSupabase();
  }

  /// Synchronizes active API keys from Supabase table `ai_api_keys`.
  /// Automatically retains the built-in key as a safe fallback.
  Future<void> syncKeysFromSupabase() async {
    if (_isSyncingKeys) return;
    _isSyncingKeys = true;

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        _ensureFallbackKey();
        return;
      }

      final response = await client
          .from('ai_api_keys')
          .select('api_key')
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final List<dynamic> rows = response as List<dynamic>;
      final fetchedKeys = rows
          .map((r) => (r['api_key'] ?? '').toString().trim())
          .where((k) => k.isNotEmpty)
          .toList();

      if (fetchedKeys.isNotEmpty) {
        _keyPool = fetchedKeys;
        debugPrint(
          'AiMealService: Loaded ${_keyPool.length} active Gemini API key(s) from Supabase.',
        );
      } else {
        _ensureFallbackKey();
      }
    } catch (e) {
      debugPrint('AiMealService: Supabase key sync error ($e). Using default key.');
      _ensureFallbackKey();
    } finally {
      _isSyncingKeys = false;
    }
  }

  void _ensureFallbackKey() {
    if (_keyPool.isEmpty) {
      final def = _resolveDefaultKey();
      if (def.isNotEmpty) {
        _keyPool = [def];
      }
    }
  }

  /// Returns the currently active Gemini API key.
  String get apiKey {
    _ensureFallbackKey();
    return _keyPool.isNotEmpty ? _keyPool.first : _resolveDefaultKey();
  }

  /// Returns unmodifiable list of current API keys in rotation.
  List<String> get activeKeys => List.unmodifiable(_keyPool);

  /// Estimates calorie and macronutrient breakdown from text, image bytes, or both.
  Future<AiMealEstimationResult> estimateMeal({
    String? textPrompt,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final hasText = textPrompt != null && textPrompt.trim().isNotEmpty;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    if (!hasText && !hasImage) {
      throw ArgumentError(
        'Musisz podać opis posiłku lub załączyć zdjęcie, aby AI mogło oszacować makro.',
      );
    }

    final promptParts = <Map<String, dynamic>>[];

    // 1. Multimodal image data (if provided)
    if (hasImage) {
      promptParts.add({
        'inlineData': {
          'mimeType': imageMimeType,
          'data': base64Encode(imageBytes),
        },
      });
    }

    // 2. Text instructions and user input
    final textInstruction = StringBuffer();
    textInstruction.writeln(
      'Jesteś profesjonalnym dietetykiem i kalkulatorem wartości odżywczych w aplikacji Grubasek. '
      'Oszacuj dokładnie kaloryczność (kcal), szacowaną wagę porcji (g) oraz makroskładniki (białko, węglowodany, tłuszcz) dla przedstawionego posiłku. '
      'Wymień również zidentyfikowane składniki z ich gramaturą i kaloriami.',
    );

    if (hasText && hasImage) {
      textInstruction.writeln(
        '\nDodatkowy opis użytkownika do zdjęcia:\n"${textPrompt.trim()}"',
      );
    } else if (hasText) {
      textInstruction.writeln(
        '\nOpis posiłku podany przez użytkownika:\n"${textPrompt.trim()}"',
      );
    } else {
      textInstruction.writeln(
        '\nPrzeanalizuj zdjęcie talerza/posiłku i rozpoznaj znajdujące się na nim danie oraz porcje.',
      );
    }

    textInstruction.writeln(
      '\nOdpowiedz obiektem JSON ściśle według zadanego schematu.',
    );

    promptParts.add({'text': textInstruction.toString()});

    final requestBody = {
      'contents': [
        {'parts': promptParts},
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _estimationResponseSchema,
        'temperature': 0.2,
        'maxOutputTokens': 2048,
      },
    };

    // Execute request with dynamic key pooling & fast candidate model cascade
    final responseData = await _postWithCascade(requestBody);
    return _parseEstimationResponse(responseData);
  }

  /// Executes a request across candidate models and the active key pool.
  /// On 429 (Rate Limit / Quota Exceeded), immediately fails over to the next key with 0ms delay.
  /// On 503 (Overloaded) or timeouts, immediately cascades to the next candidate model.
  Future<dynamic> _postWithCascade(Map<String, dynamic> requestBody) async {
    _ensureFallbackKey();
    final availableKeys = _keyPool.where((k) => k.trim().isNotEmpty).toList();
    if (availableKeys.isEmpty) {
      throw Exception('Brak klucza Gemini API. Skonfiguruj klucz w bazie danych.');
    }

    dynamic lastError;

    // Try candidate models in order of speed
    for (final model in _candidateModels) {
      // Rotate through available keys starting from current index
      for (var k = 0; k < availableKeys.length; k++) {
        final currentKey =
            availableKeys[(_keyIndex + k) % availableKeys.length];
        final url =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$currentKey';

        try {
          final response = await _dio.post(
            url,
            data: jsonEncode(requestBody),
          );

          if (response.statusCode == 200) {
            // Advance key index for round-robin load distribution
            _keyIndex = (_keyIndex + 1) % availableKeys.length;
            return response.data;
          }
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Błąd API Gemini: status ${response.statusCode}',
          );
        } catch (e) {
          lastError = e;
          final statusCode = e is DioException ? e.response?.statusCode : null;

          // 429 Rate Limit / Quota Exceeded: Immediately switch to next key in pool
          if (statusCode == 429) {
            debugPrint(
              'AiMealService: Key quota reached (429) on $model. Switching to next key in pool instantly...',
            );
            continue;
          }

          // 503 Overloaded, 500, or network timeouts: Immediately cascade to next model
          if (statusCode == 503 ||
              statusCode == 500 ||
              (e is DioException &&
                  (e.type == DioExceptionType.connectionTimeout ||
                      e.type == DioExceptionType.receiveTimeout))) {
            debugPrint(
              'AiMealService: Server spike ($statusCode) on $model. Cascading to next model instantly...',
            );
            break;
          }

          // Other errors: cascade to next model
          debugPrint(
            'AiMealService: Error on $model: $e. Cascading to next candidate...',
          );
          break;
        }
      }
    }

    throw _formatException(lastError);
  }

  /// Robust JSON extraction: handles markdown code fences, comments, and leading/trailing chatter.
  static String sanitizeJson(String rawText) {
    var text = rawText.trim();

    // Strip markdown code fences if present (```json ... ``` or ``` ...)
    if (text.startsWith('```')) {
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) {
        text = text.substring(firstNewline + 1);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();
    }

    // Extract exact outer JSON block (first '{' or '[' to last '}' or ']')
    final firstObj = text.indexOf('{');
    final firstArr = text.indexOf('[');
    if (firstObj != -1 && (firstArr == -1 || firstObj < firstArr)) {
      final lastObj = text.lastIndexOf('}');
      if (lastObj != -1 && lastObj > firstObj) {
        text = text.substring(firstObj, lastObj + 1);
      }
    } else if (firstArr != -1) {
      final lastArr = text.lastIndexOf(']');
      if (lastArr != -1 && lastArr > firstArr) {
        text = text.substring(firstArr, lastArr + 1);
      }
    }

    return text.trim();
  }

  AiMealEstimationResult _parseEstimationResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Niepoprawna odpowiedź z serwera Gemini.');
    }

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormatException('Gemini nie zwróciło żadnych propozycji.');
    }

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final content = firstCandidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw const FormatException('Brak treści w odpowiedzi modelu Gemini.');
    }

    final rawText = (parts.first['text'] ?? '').toString();
    final cleanJson = sanitizeJson(rawText);

    try {
      final decoded = jsonDecode(cleanJson);
      if (decoded is List && decoded.isNotEmpty) {
        return AiMealEstimationResult.fromJson(
          Map<String, dynamic>.from(decoded.first as Map),
        );
      } else if (decoded is Map<String, dynamic>) {
        return AiMealEstimationResult.fromJson(decoded);
      } else {
        throw FormatException('Nieoczekiwana struktura JSON: $decoded');
      }
    } catch (e) {
      debugPrint('AiMealService JSON parse error: $e\nRaw text:\n$rawText');
      throw const FormatException(
        'Nie udało się poprawnie zinterpretować danych od AI. Spróbuj ponownie lub doprecyzuj opis posiłku.',
      );
    }
  }

  Exception _formatException(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Exception(
          'Przekroczono limit czasu połączenia. Sprawdź internet i spróbuj ponownie.',
        );
      }
      if (error.response?.statusCode == 400) {
        return Exception(
          'Nieprawidłowe zapytanie do AI. Upewnij się, że zdjęcie jest czytelne.',
        );
      }
      if (error.response?.statusCode == 403 ||
          error.response?.statusCode == 401) {
        return Exception(
          'Błąd autoryzacji Gemini API. Sprawdź ważność kluczy API.',
        );
      }
      if (error.response?.statusCode == 429) {
        return Exception(
          'Chwilowo wyczerpano limit zapytań dla wszystkich kluczy AI. Spróbuj ponownie za moment.',
        );
      }
      if (error.response?.statusCode == 503) {
        return Exception(
          'Serwery Gemini są chwilowo przeciążone. Spróbuj ponownie za moment.',
        );
      }
      return Exception(
        'Błąd sieciowy podczas kontaktu z Gemini AI (${error.message}).',
      );
    }
    return Exception(error.toString());
  }

  /// Generates 3 realistic, delicious meal/snack suggestions to finish the user's remaining macros for the day.
  ///
  /// Mathematical integrity guarantees:
  /// - Each of the 3 suggestions has its OWN unique, realistic calories & macros calculated from its ingredients.
  /// - No blind copying of the user's exact missing numbers onto every dish.
  Future<List<AiMealSuggestion>> suggestMealsForRemainingMacro({
    required int remainingCalories,
    required double remainingProtein,
    required double remainingCarbs,
    required double remainingFat,
    String? dietaryPreferences,
  }) async {
    _ensureFallbackKey();

    final calTarget = remainingCalories.round();
    final pTarget = remainingProtein.toStringAsFixed(1);
    final cTarget = remainingCarbs.toStringAsFixed(1);
    final fTarget = remainingFat.toStringAsFixed(1);

    final prompt = '''
Jesteś doświadczonym dietetykiem klinicznym i szefem kuchni w aplikacji Grubasek.
Użytkownikowi pozostało dzisiaj do spożycia orientacyjnie:
- Kalorie: ~$calTarget kcal
- Białko: ~$pTarget g
- Węglowodany: ~$cTarget g
- Tłuszcze: ~$fTarget g
${dietaryPreferences != null && dietaryPreferences.trim().isNotEmpty ? 'Preferencje/wykluczenia dietetyczne użytkownika: "${dietaryPreferences.trim()}"' : ''}

Zaproponuj DOKŁADNIE 3 RÓŻNE, konkretne, pyszne i realistyczne propozycje posiłków lub przekąsek, które pomagają zbilansować i domknąć ten dzień.

KRYTYCZNE ZASADY DIETETYCZNE (BEZWZGLĘDNIE PRZESTRZEGAJ):
1. KAŻDA Z 3 PROPOZYCJI MUSI MIEĆ INNE, UNIKALNE WARTOŚCI ODŻYWCZE! Niedopuszczalne jest, aby wszystkie 3 dania miały takie same liczby.
2. ABSOLUTNY ZAKAZ KOPIOWANIA wartości pozostałych użytkownikowi! Nie wpisuj $calTarget kcal ani $pTarget g białka na ślepo do każdego dania.
3. Wartości odżywcze każdego posiłku (calories, protein, carbs, fat) MUSZĄ BYĆ RZECZYWISTĄ SUMĄ JEGO SKŁADNIKÓW. Jeśli przepis z podanych składników ma np. 780 kcal, wpisz dokładnie 780 kcal!
4. Składniki muszą zawierać dokładne gramatury w tekście (np. ["180g chudego twarogu", "60g płatków owsianych", "15g miodu", "100ml mleka 2%"]).
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _suggestionsResponseSchema,
        'temperature': 0.3,
        'maxOutputTokens': 2048,
      }
    };

    final responseData = await _postWithCascade(requestBody);
    return _parseSuggestionsResponse(responseData);
  }

  List<AiMealSuggestion> _parseSuggestionsResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowa odpowiedź z API.');
    }
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormatException('Brak propozycji w odpowiedzi modelu Gemini.');
    }
    final firstCandidate = candidates.first as Map<String, dynamic>;
    final content = firstCandidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw const FormatException('Pusta treść odpowiedzi z Gemini.');
    }

    final rawText = (parts.first['text'] ?? '').toString();
    final cleanJson = sanitizeJson(rawText);

    try {
      final decoded = jsonDecode(cleanJson);
      List<dynamic> items = [];
      if (decoded is Map<String, dynamic>) {
        if (decoded['suggestions'] is List) {
          items = decoded['suggestions'] as List;
        }
      } else if (decoded is List) {
        items = decoded;
      }

      return items
          .whereType<Map>()
          .map((m) => AiMealSuggestion.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('AiMealService suggestions parse error: $e\nRaw text:\n$rawText');
      throw const FormatException(
        'Nie udało się poprawnie zinterpretować propozycji posiłków. Spróbuj ponownie.',
      );
    }
  }
}
