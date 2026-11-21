import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_product.dart';

/// Service interfacing with the free Open Food Facts API.
/// Provides barcode product lookup and Polish localized product search,
/// with an active sanitization layer correcting community user errors
/// (impossible macros, kJ/kcal confusion, missing energy, bad barcodes).
class OpenFoodFactsService {
  final Dio _dio;
  static const _uuid = Uuid();

  static const List<String> _hosts = [
    'https://world.openfoodfacts.org',
    'https://pl.openfoodfacts.org',
    'https://world.openfoodfacts.net',
  ];

  OpenFoodFactsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent':
                      'GrubasekApp - Android/iOS/Web - Version 1.0 - https://grubasek.pages.dev',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Fetches product details by its EAN barcode from Open Food Facts database.
  /// Automatically tries fallback hosts if the primary host is temporarily unavailable (503).
  Future<FoodProduct?> getProductByBarcode(
    String barcode, {
    CancelToken? cancelToken,
  }) async {
    final cleanBarcode = barcode.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanBarcode.length < 8 || cleanBarcode.length > 14 || _isDummyBarcode(cleanBarcode)) {
      return null;
    }

    for (final host in _hosts) {
      final url = '$host/api/v0/product/$cleanBarcode.json';
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          cancelToken: cancelToken,
        );

        final data = response.data;
        if (data == null) continue;

        final status = data['status'];
        if (status != 1 && status != '1') {
          return null; // Product explicitly not found in OFF
        }

        final productData = data['product'] as Map<String, dynamic>?;
        if (productData == null) return null;

        return _mapJsonToFoodProduct(productData, barcode: cleanBarcode);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          debugPrint('OpenFoodFacts barcode request cancelled: $barcode');
          return null;
        }
        debugPrint('Host $host failed for barcode $cleanBarcode: ${e.message}');
        // Continue to fallback host
        continue;
      } catch (e, stackTrace) {
        debugPrint('Unexpected error in getProductByBarcode: $e\n$stackTrace');
        return null;
      }
    }
    return null;
  }

  /// Searches the Polish Open Food Facts database for a given query text.
  /// Uses Open Food Facts v2 search endpoint with fallback.
  Future<List<FoodProduct>> searchProducts(
    String query, {
    CancelToken? cancelToken,
    int pageSize = 25,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    for (final host in _hosts) {
      final url = '$host/api/v2/search';

      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          queryParameters: {
            'search_terms': cleanQuery,
            'countries_tags_en': 'poland',
            'page_size': pageSize,
            'fields':
                'code,product_name,product_name_pl,brands,nutriments,serving_size,serving_quantity',
          },
          cancelToken: cancelToken,
        );

        final data = response.data;
        if (data == null) continue;

        final productsJson = data['products'] as List<dynamic>?;
        if (productsJson == null || productsJson.isEmpty) {
          return [];
        }

        final results = <FoodProduct>[];
        for (final item in productsJson) {
          if (item is Map<String, dynamic>) {
            final product = _mapJsonToFoodProduct(item);
            if (product != null && product.name.trim().isNotEmpty) {
              results.add(product);
            }
          }
        }

        return results;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          debugPrint('OpenFoodFacts search request cancelled for query: $query');
          return [];
        }
        debugPrint('Host $host failed for search: ${e.message}');
        continue;
      } catch (e, stackTrace) {
        debugPrint('Unexpected error in searchProducts: $e\n$stackTrace');
        return [];
      }
    }

    return [];
  }

  /// Exposes JSON mapping for unit tests.
  @visibleForTesting
  FoodProduct? parseProductJsonForTesting(
    Map<String, dynamic> json, {
    String? barcode,
  }) {
    return _mapJsonToFoodProduct(json, barcode: barcode);
  }

  /// Parses and sanitizes an Open Food Facts product JSON object into a [FoodProduct] model,
  /// actively correcting user-submitted errors and inconsistencies.
  FoodProduct? _mapJsonToFoodProduct(
    Map<String, dynamic> json, {
    String? barcode,
  }) {
    // 1. Barcode sanitization
    final rawBarcode = (barcode ?? json['code'] as String?)?.trim();
    String? cleanBarcode;
    if (rawBarcode != null && rawBarcode.isNotEmpty) {
      final digitsOnly = rawBarcode.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length >= 8 && digitsOnly.length <= 14 && !_isDummyBarcode(digitsOnly)) {
        cleanBarcode = digitsOnly;
      }
    }

    // 2. Name extraction & sanitization
    var name = (json['product_name_pl'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      name = (json['product_name'] as String?)?.trim();
    }
    if (name == null || name.isEmpty) {
      return null;
    }

    // Clean name from garbage test data
    if (_isGarbageName(name)) {
      return null;
    }

    var brand = (json['brands'] as String?)?.trim();
    if (brand != null && brand.isNotEmpty) {
      // If brand has multiple comma-separated values, take the primary one
      final firstBrand = brand.split(',').first.trim();
      brand = firstBrand.isNotEmpty ? firstBrand : null;
    } else {
      brand = null;
    }

    // Clean redundant brand prefix in name (e.g. "Mlekovita Mleko" -> "Mleko")
    if (brand != null && name.toLowerCase().startsWith('${brand.toLowerCase()} ')) {
      name = name.substring(brand.length).trim();
    }
    // Capitalize first letter if lowercase
    if (name.isNotEmpty && name[0] == name[0].toLowerCase()) {
      name = '${name[0].toUpperCase()}${name.substring(1)}';
    }

    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    // 3. Extract and sanitize macronutrients
    var protein = _extractNutrient(
      nutriments,
      ['proteins_100g', 'proteins_value', 'proteins'],
    ).clamp(0.0, 100.0);

    var carbs = _extractNutrient(
      nutriments,
      ['carbohydrates_100g', 'carbohydrates_value', 'carbohydrates'],
    ).clamp(0.0, 100.0);

    var fat = _extractNutrient(
      nutriments,
      ['fat_100g', 'fat_value', 'fat'],
    ).clamp(0.0, 100.0);

    final fiberRaw = _extractNutrientOrNull(
      nutriments,
      ['fiber_100g', 'fiber_value', 'fiber'],
    )?.clamp(0.0, 100.0);

    // 4. Validate physical macro sum
    final macroSum = protein + carbs + fat;
    if (macroSum > 105.0) {
      // If user entered impossible macros (e.g. sum is > 105g in 100g of product)
      if (macroSum <= 130.0) {
        // Proportionally rescale if slightly over
        final scale = 100.0 / macroSum;
        protein = (protein * scale * 10.0).roundToDouble() / 10.0;
        carbs = (carbs * scale * 10.0).roundToDouble() / 10.0;
        fat = (fat * scale * 10.0).roundToDouble() / 10.0;
      } else {
        // Severely corrupted product entry (e.g. sum > 130g) -> discard
        return null;
      }
    }

    // 5. Energy extraction & auto-correction of community user errors
    final theoreticalKcal = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0);
    var calories = _extractNutrient(
      nutriments,
      ['energy-kcal_100g', 'energy-kcal_value', 'energy-kcal'],
      fallbackMultiplier: 0.239006, // from kJ if only energy_100g exists
      fallbackKeys: ['energy_100g', 'energy_value'],
    );

    // Error case A: kcal is 0 or missing, but macros are present
    if (calories <= 0.0 && theoreticalKcal > 0.0) {
      calories = (theoreticalKcal * 10.0).roundToDouble() / 10.0;
    }
    // Error case A2: completely blank/zero calories and macros for non-zero calorie foods (e.g. cookies)
    else if (calories <= 0.0 && theoreticalKcal <= 0.0) {
      final lowerName = name.toLowerCase();
      final isNaturallyZero = lowerName.contains('woda') ||
          lowerName.contains('water') ||
          lowerName.contains('herbata') ||
          lowerName.contains('tea') ||
          lowerName.contains('kawa') ||
          lowerName.contains('coffee') ||
          lowerName.contains('zero') ||
          lowerName.contains('pepsi max') ||
          lowerName.contains('cola light');
      if (!isNaturallyZero) {
        // Discard unpopulated dummy items from Open Food Facts
        return null;
      }
    }
    // Error case B: user entered kJ in the kcal field (e.g. 2100 kcal instead of 500 kcal)
    else if (calories > 950.0 || (theoreticalKcal > 15.0 && calories > 2.8 * theoreticalKcal)) {
      final kjToKcal = calories * 0.239006;
      if (kjToKcal <= 900.0 && (kjToKcal - theoreticalKcal).abs() < 120.0) {
        calories = (kjToKcal * 10.0).roundToDouble() / 10.0;
      } else if (theoreticalKcal > 0.0) {
        calories = (theoreticalKcal * 10.0).roundToDouble() / 10.0;
      } else {
        calories = calories.clamp(0.0, 900.0);
      }
    }
    // Error case C: calories significantly mismatch macros (|calories - theoretical| > 150)
    else if (theoreticalKcal > 30.0 && (calories - theoreticalKcal).abs() > 150.0) {
      calories = (theoreticalKcal * 10.0).roundToDouble() / 10.0;
    }

    calories = (calories * 10.0).roundToDouble() / 10.0;

    // Serving size & weight parsing
    final servingSizeString = json['serving_size'] as String?;
    final servingQuantity = _parseServingQuantity(
      json['serving_quantity'],
      servingSizeString,
    );

    return FoodProduct(
      id: _uuid.v4(),
      barcode: cleanBarcode,
      name: name,
      brand: brand,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      fiberPer100g: fiberRaw,
      servingSizeGrams: servingQuantity,
      servingName: servingSizeString?.trim().isNotEmpty == true
          ? servingSizeString!.trim()
          : null,
      isCustom: false,
    );
  }

  static bool _isDummyBarcode(String barcode) {
    if (barcode.length < 8) return true;
    final firstChar = barcode[0];
    if (barcode.split('').every((c) => c == firstChar)) return true;
    if (barcode == '12345678' || barcode == '1234567890123') return true;
    return false;
  }

  static bool _isGarbageName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.length < 2) return true;
    if (RegExp(r'^[\s\.\,\-_=+!@#\$%\^&\*\(\)]+$').hasMatch(lower)) return true;
    const banned = ['test', 'asdf', 'qwer', 'brak', 'nieznany', 'unknown', 'delete', 'usun'];
    if (banned.contains(lower)) return true;
    return false;
  }

  /// Helper to extract numeric nutrient value from various possible keys.
  double _extractNutrient(
    Map<String, dynamic> nutriments,
    List<String> keys, {
    double fallbackMultiplier = 1.0,
    List<String>? fallbackKeys,
  }) {
    for (final key in keys) {
      final val = nutriments[key];
      if (val != null) {
        final parsed = _toDouble(val);
        if (parsed != null) return (parsed * 10.0).roundToDouble() / 10.0;
      }
    }

    if (fallbackKeys != null) {
      for (final key in fallbackKeys) {
        final val = nutriments[key];
        if (val != null) {
          final parsed = _toDouble(val);
          if (parsed != null) {
            return ((parsed * fallbackMultiplier) * 10.0).roundToDouble() / 10.0;
          }
        }
      }
    }

    return 0.0;
  }

  double? _extractNutrientOrNull(
    Map<String, dynamic> nutriments,
    List<String> keys,
  ) {
    for (final key in keys) {
      final val = nutriments[key];
      if (val != null) {
        final parsed = _toDouble(val);
        if (parsed != null) return (parsed * 10.0).roundToDouble() / 10.0;
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  /// Parses serving weight in grams from serving_quantity or serving_size string.
  double _parseServingQuantity(dynamic quantity, String? sizeString) {
    if (quantity is num && quantity > 0) {
      return quantity.toDouble();
    }
    if (quantity is String) {
      final parsed = double.tryParse(quantity.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) return parsed;
    }

    if (sizeString != null) {
      final match = RegExp(r'(\d+([.,]\d+)?)\s*g', caseSensitive: false)
          .firstMatch(sizeString);
      if (match != null) {
        final numStr = match.group(1)?.replaceAll(',', '.');
        if (numStr != null) {
          final parsed = double.tryParse(numStr);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }

    return 100.0; // Default serving size is 100g
  }
}
