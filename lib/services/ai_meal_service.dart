import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_meal_models.dart';

/// Service responsible for estimating meal macros and calories via Gemini AI.
/// Supports text descriptions, image photos (camera / gallery), and photo + text notes.
class AiMealService {
  static const String _defaultEncodedKey =
      'QVEuQWI4Uk42SXYxTHhlSFQxZjNnLUFmV0JWX2k1X0NKenVtOUk2aUpfSnRoVThyYkswZmc=';
  static const String _prefApiKey = 'gemini_api_key_override';

  static String _resolveDefaultKey() {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    try {
      return utf8.decode(base64Decode(_defaultEncodedKey));
    } catch (_) {
      return '';
    }
  }

  // Current primary fast models supported by Google Gemini API
  static const String _primaryModel = 'gemini-3.5-flash-lite';
  static const String _fallbackModel = 'gemini-3.8-flash';

  final Dio _dio;
  String? _customApiKey;

  AiMealService({Dio? dio}) : _dio = dio ?? Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 40),
            sendTimeout: const Duration(seconds: 35),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  /// Loads any custom API key saved by the user in SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString(_prefApiKey);
    } catch (_) {}
  }

  /// Returns the active API key (custom if configured, otherwise default).
  String get apiKey =>
      _customApiKey?.isNotEmpty == true ? _customApiKey! : _resolveDefaultKey();

  /// Saves or removes a custom user API key.
  Future<void> setCustomApiKey(String? newKey) async {
    _customApiKey = newKey?.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiKey != null && _customApiKey!.isNotEmpty) {
        await prefs.setString(_prefApiKey, _customApiKey!);
      } else {
        await prefs.remove(_prefApiKey);
      }
    } catch (_) {}
  }

  /// Estimates calorie and macronutrient breakdown from text, image bytes, or both.
  ///
  /// - [textPrompt]: Optional user description (e.g. "Jajecznica z 3 jaj na maśle...").
  /// - [imageBytes]: Optional raw image data (JPEG, PNG, WEBP).
  /// - [imageMimeType]: MIME type of image (defaults to 'image/jpeg').
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
      '\nOdpowiedz WYŁĄCZNIE poprawnym obiektem JSON w poniższym formacie (bez zbędnego tekstu pobocznego):\n'
      '{\n'
      '  "mealName": "Krótka, czytelna nazwa posiłku po polsku",\n'
      '  "calories": 450,\n'
      '  "proteinGrams": 24.5,\n'
      '  "carbsGrams": 42.0,\n'
      '  "fatGrams": 16.0,\n'
      '  "estimatedWeightGrams": 320,\n'
      '  "confidence": "Wysoka" lub "Średnia",\n'
      '  "adviceOrNotes": "Krótka (1-2 zdania) wskazówka dietetyczna dot. tego posiłku po polsku",\n'
      '  "ingredients": [\n'
      '    {\n'
      '      "name": "Nazwa składnika",\n'
      '      "weightGrams": 100,\n'
      '      "calories": 150,\n'
      '      "protein": 10,\n'
      '      "carbs": 20,\n'
      '      "fat": 5\n'
      '    }\n'
      '  ]\n'
      '}',
    );

    promptParts.add({'text': textInstruction.toString()});

    final requestBody = {
      'contents': [
        {'parts': promptParts},
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2, // Low temperature for consistent, factual nutritional math
      },
    };

    // Try primary model first, fallback if unavailable
    try {
      return await _callGeminiModel(_primaryModel, requestBody);
    } catch (primaryError) {
      debugPrint('AiMealService: $_primaryModel call failed: $primaryError. Trying $_fallbackModel...');
      try {
        return await _callGeminiModel(_fallbackModel, requestBody);
      } catch (fallbackError) {
        debugPrint('AiMealService: $_fallbackModel also failed: $fallbackError');
        throw _formatException(fallbackError);
      }
    }
  }

  Future<AiMealEstimationResult> _callGeminiModel(
    String model,
    Map<String, dynamic> requestBody,
  ) async {
    final currentKey = apiKey;
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$currentKey';

    final response = await _dio.post(
      url,
      data: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Błąd API Gemini: status ${response.statusCode}',
      );
    }

    final data = response.data;
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

    final rawText = (parts.first['text'] ?? '').toString().trim();
    if (rawText.isEmpty) {
      throw const FormatException('Pusta odpowiedź z modelu Gemini.');
    }

    // Clean any markdown code fences if present (e.g. ```json ... ```)
    String cleanJson = rawText;
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

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
  }

  Exception _formatException(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Exception('Przekroczono limit czasu połączenia. Sprawdź internet i spróbuj ponownie.');
      }
      if (error.response?.statusCode == 400) {
        return Exception('Nieprawidłowe zapytanie do AI. Upewnij się, że zdjęcie jest czytelne.');
      }
      if (error.response?.statusCode == 403 || error.response?.statusCode == 401) {
        return Exception('Błąd autoryzacji Gemini API. Sprawdź ważność klucza API w ustawieniach.');
      }
      if (error.response?.statusCode == 429) {
        return Exception('Przekroczono chwilowy limit zapytań (Rate Limit). Odczekaj chwilę.');
      }
      if (error.response?.statusCode == 503) {
        return Exception('Serwery Gemini są chwilowo przeciążone. Spróbuj ponownie za moment.');
      }
      return Exception('Błąd sieciowy podczas kontaktu z Gemini AI (${error.message}).');
    }
    return Exception(error.toString());
  }

  /// Generates 3 realistic, delicious meal/snack suggestions to finish the user's remaining macros for the day.
  Future<List<AiMealSuggestion>> suggestMealsForRemainingMacro({
    required int remainingCalories,
    required double remainingProtein,
    required double remainingCarbs,
    required double remainingFat,
    String? dietaryPreferences,
  }) async {
    final key = apiKey;
    if (key.isEmpty) {
      throw Exception('Brak klucza Gemini API. Skonfiguruj klucz w ustawieniach.');
    }

    final prompt = '''
Jesteś doświadczonym dietetykiem klinicznym i sportowym w aplikacji Grubasek.
Użytkownikowi pozostało dzisiaj do zjedzenia:
- Kalorie: $remainingCalories kcal
- Białko: ${remainingProtein.toStringAsFixed(1)} g
- Węglowodany: ${remainingCarbs.toStringAsFixed(1)} g
- Tłuszcze: ${remainingFat.toStringAsFixed(1)} g
${dietaryPreferences != null && dietaryPreferences.isNotEmpty ? 'Preferencje/wykluczenia: $dietaryPreferences' : ''}

Zaproponuj DOKŁADNIE 3 konkretne, pyszne, realistyczne i proste w przygotowaniu propozycje posiłków lub przekąsek, które idealnie domykają ten bilans (lub mieszczą się w tych wartościach).
Każda propozycja musi zawierać:
- title: chwytliwa nazwa dania po polsku (np. "Kremowy twaróg z malinami i orzechami włoskimi")
- description: krótki, 1-2 zdaniowy opis przygotowania
- prepTimeMinutes: czas przygotowania w minutach (liczba całkowita)
- calories: całkowita kaloryczność posiłku (liczba całkowita, bliska $remainingCalories)
- protein: białko w gramach (bliskie ${remainingProtein.toStringAsFixed(1)})
- carbs: węglowodany w gramach (bliskie ${remainingCarbs.toStringAsFixed(1)})
- fat: tłuszcze w gramach (bliskie ${remainingFat.toStringAsFixed(1)})
- ingredients: lista składników z gramaturą (np. ["150g chudego twarogu", "80g mrożonych malin", "15g orzechów włoskich"])

Zwróć odpowiedź WYŁĄCZNIE jako poprawny JSON o schemacie:
{
  "suggestions": [
    {
      "title": "string",
      "description": "string",
      "prepTimeMinutes": 10,
      "calories": 350,
      "protein": 30.0,
      "carbs": 25.0,
      "fat": 8.0,
      "ingredients": ["string"]
    }
  ]
}
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
        'temperature': 0.4,
      }
    };

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$_primaryModel:generateContent?key=$key',
        data: requestBody,
      );
      return _parseSuggestionsResponse(response.data);
    } catch (primaryError) {
      debugPrint('Gemini primary model failed: $primaryError. Trying fallback $_fallbackModel...');
      try {
        final fallbackResponse = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/$_fallbackModel:generateContent?key=$key',
          data: requestBody,
        );
        return _parseSuggestionsResponse(fallbackResponse.data);
      } catch (fallbackError) {
        throw _formatException(fallbackError);
      }
    }
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
    final rawText = (parts.first['text'] ?? '').toString().trim();
    String cleanJson = rawText;
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

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
  }
}
