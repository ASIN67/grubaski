import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_product.dart';

/// Service interfacing with the free Open Food Facts API.
/// Provides barcode product lookup and Polish localized product search.
class OpenFoodFactsService {
  final Dio _dio;
  static const _uuid = Uuid();

  OpenFoodFactsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent':
                      'GrubasekApp/1.0.0 (Flutter; Android/iOS; https://github.com/example/grubasek)',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Fetches product details by its EAN barcode from Open Food Facts World database.
  /// Endpoint: https://world.openfoodfacts.org/api/v0/product/{barcode}.json
  Future<FoodProduct?> getProductByBarcode(
    String barcode, {
    CancelToken? cancelToken,
  }) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final url =
        'https://world.openfoodfacts.org/api/v0/product/$cleanBarcode.json';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null) return null;

      // Status 1 indicates product was found in Open Food Facts
      final status = data['status'];
      if (status != 1 && status != '1') {
        return null;
      }

      final productData = data['product'] as Map<String, dynamic>?;
      if (productData == null) return null;

      return _mapJsonToFoodProduct(productData, barcode: cleanBarcode);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('OpenFoodFacts barcode request cancelled: $barcode');
        return null;
      }
      debugPrint('Error fetching product by barcode $barcode: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in getProductByBarcode: $e\n$stackTrace');
      return null;
    }
  }

  /// Searches the Polish Open Food Facts database for a given query text.
  /// Endpoint: https://pl.openfoodfacts.org/cgi/search.pl?search_terms={query}&search_simple=1&action=process&json=1
  Future<List<FoodProduct>> searchProducts(
    String query, {
    CancelToken? cancelToken,
    int pageSize = 25,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    const url = 'https://pl.openfoodfacts.org/cgi/search.pl';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'search_terms': cleanQuery,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': pageSize,
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null) return [];

      final productsJson = data['products'] as List<dynamic>?;
      if (productsJson == null || productsJson.isEmpty) {
        return [];
      }

      final results = <FoodProduct>[];
      for (final item in productsJson) {
        if (item is Map<String, dynamic>) {
          final product = _mapJsonToFoodProduct(item);
          // Only include items that have a recognizable name and non-zero calorie data
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
      debugPrint('Network error in searchProducts: ${e.message}');
      return [];
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in searchProducts: $e\n$stackTrace');
      return [];
    }
  }

  /// Parses an Open Food Facts product JSON object into a [FoodProduct] model.
  FoodProduct? _mapJsonToFoodProduct(
    Map<String, dynamic> json, {
    String? barcode,
  }) {
    // Prefer Polish localized name if available
    final name = (json['product_name_pl'] as String?)?.trim().isNotEmpty == true
        ? (json['product_name_pl'] as String).trim()
        : (json['product_name'] as String?)?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    final brand = (json['brands'] as String?)?.trim();
    final itemBarcode = barcode ?? (json['code'] as String?)?.trim();

    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    // Energy extraction: Open Food Facts stores energy in kcal
    final calories = _extractNutrient(
      nutriments,
      ['energy-kcal_100g', 'energy-kcal_value', 'energy-kcal'],
      fallbackMultiplier: 0.239006, // from kJ if only energy_100g in kJ exists
      fallbackKeys: ['energy_100g', 'energy_value'],
    );

    final protein = _extractNutrient(
      nutriments,
      ['proteins_100g', 'proteins_value', 'proteins'],
    );

    final carbs = _extractNutrient(
      nutriments,
      ['carbohydrates_100g', 'carbohydrates_value', 'carbohydrates'],
    );

    final fat = _extractNutrient(
      nutriments,
      ['fat_100g', 'fat_value', 'fat'],
    );

    final fiberRaw = _extractNutrientOrNull(
      nutriments,
      ['fiber_100g', 'fiber_value', 'fiber'],
    );

    // Serving size & weight parsing
    final servingSizeString = json['serving_size'] as String?;
    final servingQuantity = _parseServingQuantity(
      json['serving_quantity'],
      servingSizeString,
    );

    return FoodProduct(
      id: _uuid.v4(),
      barcode: itemBarcode,
      name: name,
      brand: brand?.isNotEmpty == true ? brand : null,
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

    // Try parsing regex from serving_size like "30 g" or "100g"
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
