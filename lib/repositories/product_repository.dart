import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import '../services/open_food_facts_service.dart';
import '../services/supabase_service.dart';
import '../utils/string_utils.dart';

/// Repository managing food products: local cached items, custom user-created
/// products, and remote catalog lookups via Supabase public_products and Open Food Facts.
class ProductRepository {
  final HiveService _hiveService;
  final OpenFoodFactsService _openFoodFactsService;
  final SupabaseService _supabaseService;
  static const _uuid = Uuid();

  ProductRepository({
    HiveService? hiveService,
    OpenFoodFactsService? openFoodFactsService,
    SupabaseService? supabaseService,
  })  : _hiveService = hiveService ?? HiveService.instance,
        _openFoodFactsService = openFoodFactsService ?? OpenFoodFactsService(),
        _supabaseService = supabaseService ?? SupabaseService.instance;

  Box<FoodProduct> get _box => _hiveService.foodProductsBox;
  List<_IndexedProduct>? _cachedIndex;

  void _invalidateIndex() {
    _cachedIndex = null;
  }

  List<_IndexedProduct> _getIndex() {
    final cached = _cachedIndex;
    if (cached != null && cached.length == _box.length) {
      return cached;
    }
    final index = _box.values.map((p) => _IndexedProduct(
      product: p,
      nameNorm: normalizeForSearch(p.name),
      brandNorm: p.brand != null ? normalizeForSearch(p.brand!) : null,
      barcode: p.barcode?.trim() ?? '',
    )).toList(growable: false);
    _cachedIndex = index;
    return index;
  }

  /// Returns all food products saved in local storage.
  List<FoodProduct> getAllLocalProducts() {
    return _box.values.toList();
  }

  /// Returns a specific product by its internal [id] from local storage, or null if absent.
  FoodProduct? getProductById(String id) {
    return _box.get(id);
  }

  /// Searches local storage for a product matching the given [barcode].
  FoodProduct? getLocalProductByBarcode(String barcode) {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final index = _getIndex();
    for (final item in index) {
      if (item.barcode == cleanBarcode) {
        return item.product;
      }
    }
    return null;
  }

  /// Finds a product by its [barcode]. First checks local cache. If not found locally
  /// and [searchRemoteIfNotFound] is true, queries Open Food Facts API and caches
  /// the result locally upon successful discovery.
  Future<FoodProduct?> findProductByBarcode(
    String barcode, {
    bool searchRemoteIfNotFound = true,
  }) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // 1. Check local Hive cache
    final localProduct = getLocalProductByBarcode(cleanBarcode);
    if (localProduct != null) {
      return localProduct;
    }

    if (!searchRemoteIfNotFound) {
      return null;
    }

    // 2. Query Supabase public_products catalog
    try {
      final table = _supabaseService.publicProductsTable;
      if (table != null) {
        final row =
            await table.select().eq('barcode', cleanBarcode).maybeSingle();
        if (row != null) {
          final product = _mapRowToFoodProduct(row);
          final cached = await cacheRemoteProducts([product]);
          return cached.single;
        }
      }
    } catch (e) {
      debugPrint('ProductRepository: Supabase barcode search failed ($e)');
    }

    // 3. Query remote Open Food Facts API
    final remoteProduct =
        await _openFoodFactsService.getProductByBarcode(cleanBarcode);

    if (remoteProduct == null) return null;
    final cached = await cacheRemoteProducts([remoteProduct]);
    return cached.single;
  }

  /// Persists a food product in local storage using its [FoodProduct.id] as key.
  Future<void> saveProduct(FoodProduct product) async {
    await _box.put(product.id, product);
    _invalidateIndex();
  }

  /// Persists multiple food products in a single batch operation.
  Future<void> saveProducts(Iterable<FoodProduct> products) async {
    if (products.isEmpty) return;
    final map = {for (final p in products) p.id: p};
    await _box.putAll(map);
    _invalidateIndex();
  }

  /// Resolves remote results to cached products, preserving their favorite state.
  Future<List<FoodProduct>> cacheRemoteProducts(
    Iterable<FoodProduct> products,
  ) async {
    final byBarcode = <String, FoodProduct>{
      for (final product in _box.values)
        if (product.barcode != null && product.barcode!.isNotEmpty)
          product.barcode!: product,
    };
    final newProducts = <String, FoodProduct>{};
    final results = <String, FoodProduct>{};
    for (final product in products) {
      final cached = _box.get(product.id) ??
          byBarcode[product.barcode] ??
          newProducts[product.id];
      final resolved = cached ?? product;
      if (cached == null) {
        newProducts[product.id] = product;
        final barcode = product.barcode;
        if (barcode != null && barcode.isNotEmpty) {
          byBarcode[barcode] = product;
        }
      }
      results[resolved.id] = resolved;
    }
    if (newProducts.isNotEmpty) {
      await _box.putAll(newProducts);
      _invalidateIndex();
    }
    return results.values.toList();
  }

  Future<void> toggleFavorite(FoodProduct product) async {
    final current = _box.get(product.id) ??
        (product.barcode == null
            ? null
            : getLocalProductByBarcode(product.barcode!));
    await saveProduct(
      (current ?? product)
          .copyWith(isFavorite: !(current?.isFavorite ?? false)),
    );
  }

  /// Stores the recipe and its computed nutrition in the same Hive record.
  Future<FoodProduct> createRecipe({
    required String name,
    required List<RecipeIngredient> ingredients,
  }) async {
    if (name.trim().isEmpty ||
        ingredients.isEmpty ||
        ingredients.any((ingredient) =>
            ingredient.product.usesPortions ||
            !ingredient.grams.isFinite ||
            ingredient.grams <= 0)) {
      throw ArgumentError('A recipe requires a name and valid ingredients.');
    }

    final totals = RecipeIngredient.totalNutrition(ingredients);
    if ([
      totals.calories,
      totals.protein,
      totals.carbs,
      totals.fat,
      totals.fiber,
    ].any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Recipe nutrition must be finite and nonnegative.');
    }
    final recipe = FoodProduct(
      id: _uuid.v4(),
      name: name.trim(),
      caloriesPer100g: totals.calories,
      proteinPer100g: totals.protein,
      carbsPer100g: totals.carbs,
      fatPer100g: totals.fat,
      fiberPer100g: totals.fiber,
      isCustom: true,
      recipeIngredients: List.unmodifiable(ingredients),
    );
    await saveProduct(recipe);
    return recipe;
  }

  /// Deletes a food product by its [id] from local storage.
  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
    _invalidateIndex();
  }

  /// Creates and saves a new custom food product authored by the user.
  Future<FoodProduct> createCustomProduct({
    required String name,
    String? brand,
    String? barcode,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    double? fiberPer100g,
    double servingSizeGrams = 100.0,
    String? servingName,
  }) async {
    final customProduct = FoodProduct(
      id: _uuid.v4(),
      barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      name: name.trim(),
      brand: brand?.trim().isEmpty == true ? null : brand?.trim(),
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      fiberPer100g: fiberPer100g,
      servingSizeGrams: servingSizeGrams,
      servingName:
          servingName?.trim().isEmpty == true ? null : servingName?.trim(),
      isCustom: true,
    );

    await saveProduct(customProduct);

    // Automatically send new custom product to Supabase public_products table
    // so it is shared and available for online searches, without blocking local save.
    unawaited(uploadProductToSupabase(customProduct));

    return customProduct;
  }

  /// Uploads a custom product to Supabase public_products table so it is shared with other users.
  Future<void> uploadProductToSupabase(FoodProduct product) async {
    try {
      final table = _supabaseService.publicProductsTable;
      if (table == null) return;
      final userId = _supabaseService.currentUserId;

      await table.upsert({
        'id': product.id,
        'barcode': product.barcode,
        'name': product.name,
        'brand': product.brand,
        'calories_per_100g': product.caloriesPer100g,
        'protein_per_100g': product.proteinPer100g,
        'carbs_per_100g': product.carbsPer100g,
        'fat_per_100g': product.fatPer100g,
        'fiber_per_100g': product.fiberPer100g,
        'serving_size_grams': product.servingSizeGrams,
        'serving_name': product.servingName,
        'is_custom': true,
        if (userId != null) 'created_by': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('ProductRepository: Uploaded custom product ${product.id} to Supabase.');
    } catch (e) {
      debugPrint('ProductRepository: Failed to upload custom product to Supabase: $e');
    }
  }

  /// Pushes any local custom products to Supabase in the background.
  Future<void> syncLocalCustomProducts() async {
    try {
      final custom = getCustomProducts();
      for (final product in custom) {
        unawaited(uploadProductToSupabase(product));
      }
    } catch (e) {
      debugPrint('ProductRepository: Failed to sync local custom products: $e');
    }
  }

  /// Returns all custom products created by the user.
  List<FoodProduct> getCustomProducts() {
    return _box.values.where((p) => p.isCustom).toList();
  }

  /// Performs an intelligent, prioritized local search across product name, brand,
  /// and barcode, with full support for Polish diacritics stripping (e.g. "bulka" -> "bułka",
  /// "twarog" -> "twaróg", "jajko" -> "jajko").
  ///
  /// Ranking priority:
  /// 1. Exact match or starts-with query in product name.
  /// 2. Word boundary match or contains query in product name or brand.
  /// 3. Favorite products ([FoodProduct.isFavorite]) receive a light bonus.
  List<FoodProduct> searchLocalProducts(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return getAllLocalProducts();

    final queryNorm = normalizeForSearch(cleanQuery);
    final queryTokens = queryNorm
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    final scored = <_ScoredProduct>[];
    final index = _getIndex();

    for (final item in index) {
      final score = _calculateSearchScore(
        product: item.product,
        nameNorm: item.nameNorm,
        brandNorm: item.brandNorm,
        barcode: item.barcode,
        queryNorm: queryNorm,
        queryTokens: queryTokens,
        cleanBarcodeQuery: cleanQuery,
      );

      if (score > 0) {
        scored.add(_ScoredProduct(item.product, score));
      }
    }

    scored.sort();
    return scored.map((item) => item.product).toList();
  }

  int _calculateSearchScore({
    required FoodProduct product,
    required String nameNorm,
    required String? brandNorm,
    required String barcode,
    required String queryNorm,
    required List<String> queryTokens,
    required String cleanBarcodeQuery,
  }) {

    var baseScore = 0;

    // 1. Exact match on name
    if (nameNorm == queryNorm) {
      baseScore = 1000;
    }
    // 2. Starts-with match on name
    else if (nameNorm.startsWith(queryNorm)) {
      final closeness = (30 - (nameNorm.length - queryNorm.length)).clamp(0, 30);
      baseScore = 800 + closeness;
    }
    // 3. Name contains query substring
    else if (nameNorm.contains(queryNorm)) {
      final idx = nameNorm.indexOf(queryNorm);
      if (_isWordBoundary(nameNorm, idx)) {
        baseScore = 650;
      } else {
        baseScore = 500;
      }
    }

    // Brand matching
    if (brandNorm != null) {
      var brandScore = 0;
      if (brandNorm == queryNorm) {
        brandScore = 450;
      } else if (brandNorm.startsWith(queryNorm)) {
        brandScore = 400;
      } else if (brandNorm.contains(queryNorm)) {
        brandScore = 300;
      }
      if (brandScore > baseScore) {
        baseScore = brandScore;
      }
    }

    // Barcode matching
    if (cleanBarcodeQuery.isNotEmpty && barcode.isNotEmpty) {
      var barcodeScore = 0;
      if (barcode == cleanBarcodeQuery) {
        barcodeScore = 950;
      } else if (barcode.contains(cleanBarcodeQuery)) {
        barcodeScore = 250;
      }
      if (barcodeScore > baseScore) {
        baseScore = barcodeScore;
      }
    }

    // Multi-token matching (when query has multiple words)
    if (baseScore == 0 && queryTokens.length > 1) {
      final combined = brandNorm != null ? '$nameNorm $brandNorm' : nameNorm;
      final allMatch = queryTokens.every((token) => combined.contains(token));
      if (allMatch) {
        final allInName =
            queryTokens.every((token) => nameNorm.contains(token));
        baseScore = allInName ? 420 : 380;
      }
    }

    if (baseScore == 0) return 0;

    // Light bonus for favorite products
    if (product.isFavorite) {
      baseScore += 35;
    }

    return baseScore;
  }

  static bool _isWordBoundary(String text, int index) {
    if (index <= 0) return true;
    final prev = text.codeUnitAt(index - 1);
    return prev == 32 /* space */ ||
        prev == 40 /* ( */ ||
        prev == 41 /* ) */ ||
        prev == 45 /* - */ ||
        prev == 47 /* / */ ||
        prev == 44 /* , */ ||
        prev == 46 /* . */;
  }

  /// Searches for products matching [query]. Returns local results first, and if
  /// [includeRemote] is true, queries Supabase public_products and Open Food Facts
  /// and merges results without duplicates.
  /// Remote products are also cached locally for offline convenience.
  Future<List<FoodProduct>> searchProducts(
    String query, {
    bool includeRemote = true,
    int remotePageSize = 25,
  }) async {
    final cleanQuery = query.trim();
    final localMatches = searchLocalProducts(cleanQuery);

    if (!includeRemote || cleanQuery.length < 2) {
      return localMatches;
    }

    try {
      // Concurrently query remote sources: Supabase public_products and Open Food Facts
      final remoteFutures = <Future<List<FoodProduct>>>[
        _searchSupabaseProducts(cleanQuery, limit: remotePageSize),
        _openFoodFactsService
            .searchProducts(cleanQuery, pageSize: remotePageSize)
            .catchError((e) {
          debugPrint('Open Food Facts search failed: $e');
          return <FoodProduct>[];
        }),
      ];

      final results = await Future.wait(remoteFutures);
      final remoteMatches = [
        ...results[0], // Supabase matches first
        ...results[1], // Open Food Facts matches
      ];

      final cached = await cacheRemoteProducts(remoteMatches);
      return {
        for (final product in searchLocalProducts(cleanQuery))
          product.id: product,
        for (final product in cached) product.id: product,
      }.values.toList();
    } catch (e) {
      // In case of network errors, degrade gracefully to local matches
      debugPrint('Remote product search failed: $e. Returning local matches.');
      return localMatches;
    }
  }

  /// Searches online catalogs (Supabase shared catalog first, then Open Food Facts).
  /// Respects [cancelToken] to abort in-flight requests when typing quickly.
  Future<List<FoodProduct>> searchRemoteProducts(
    String query, {
    int pageSize = 30,
    CancelToken? cancelToken,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return const [];

    try {
      final remoteFutures = <Future<List<FoodProduct>>>[
        _searchSupabaseProducts(cleanQuery, limit: pageSize),
        _openFoodFactsService
            .searchProducts(
              cleanQuery,
              pageSize: pageSize,
              cancelToken: cancelToken,
            )
            .catchError((e) {
          debugPrint('Open Food Facts search failed: $e');
          return <FoodProduct>[];
        }),
      ];

      final results = await Future.wait(remoteFutures);
      if (cancelToken?.isCancelled ?? false) return const [];

      final seenIds = <String>{};
      final seenBarcodes = <String>{};
      final merged = <FoodProduct>[];

      for (final list in results) {
        for (final product in list) {
          if (!seenIds.add(product.id)) continue;
          final barcode = product.barcode;
          if (barcode != null &&
              barcode.isNotEmpty &&
              !seenBarcodes.add(barcode)) {
            continue;
          }
          merged.add(product);
        }
      }

      return merged;
    } catch (e) {
      debugPrint('Remote product search failed: $e');
      return const [];
    }
  }

  Future<List<FoodProduct>> _searchSupabaseProducts(
    String query, {
    int limit = 25,
  }) async {
    try {
      final table = _supabaseService.publicProductsTable;
      if (table == null) return const [];
      final clean = query.trim();
      if (clean.isEmpty) return const [];

      final sanitized = clean.replaceAll(RegExp(r'[,()"\\]'), ' ').trim();
      final tokens = sanitized
          .split(RegExp(r'\s+'))
          .where((t) => t.length >= 2)
          .toList(growable: false);

      final conditions = <String>[
        'name.ilike.%$sanitized%',
        'brand.ilike.%$sanitized%',
      ];
      if (RegExp(r'^\d+$').hasMatch(sanitized)) {
        conditions.add('barcode.eq.$sanitized');
      }
      for (final token in tokens.take(3)) {
        if (token != sanitized) {
          conditions.add('name.ilike.%$token%');
        }
      }

      final response = await table
          .select()
          .or(conditions.join(','))
          .limit(limit);

      final list = <FoodProduct>[];
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        list.add(_mapRowToFoodProduct(map));
      }
      return list;
    } catch (e) {
      debugPrint('ProductRepository: Supabase product search failed: $e');
      return const [];
    }
  }

  static FoodProduct _mapRowToFoodProduct(Map<String, dynamic> row) {
    return FoodProduct(
      id: row['id'] as String,
      barcode: row['barcode'] as String?,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      caloriesPer100g: (row['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (row['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (row['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (row['fat_per_100g'] as num).toDouble(),
      fiberPer100g: (row['fiber_per_100g'] as num?)?.toDouble(),
      servingSizeGrams:
          (row['serving_size_grams'] as num?)?.toDouble() ?? 100.0,
      servingName: row['serving_name'] as String?,
      isCustom: row['is_custom'] as bool? ?? false,
    );
  }

  /// Reactive stream yielding the full list of local products whenever the box changes.
  Stream<List<FoodProduct>> watchProducts() async* {
    yield getAllLocalProducts();
    yield* _box.watch().map((_) => getAllLocalProducts());
  }

  Stream<BoxEvent> get productChanges => _box.watch();

  /// Provides a [ValueListenable] for Flutter UI widgets.
  ValueListenable<Box<FoodProduct>> get productsListenable {
    return _box.listenable();
  }
}

class _ScoredProduct implements Comparable<_ScoredProduct> {
  final FoodProduct product;
  final int score;

  const _ScoredProduct(this.product, this.score);

  @override
  int compareTo(_ScoredProduct other) {
    // 1. Higher score first
    final scoreComp = other.score.compareTo(score);
    if (scoreComp != 0) return scoreComp;

    // 2. Favorite bonus tie-breaker
    if (product.isFavorite != other.product.isFavorite) {
      return product.isFavorite ? -1 : 1;
    }

    // 3. Shorter name length
    final lenComp = product.name.length.compareTo(other.product.name.length);
    if (lenComp != 0) return lenComp;

    // 4. Alphabetical tie-breaker
    return product.name.compareTo(other.product.name);
  }
}

class _IndexedProduct {
  final FoodProduct product;
  final String nameNorm;
  final String? brandNorm;
  final String barcode;

  const _IndexedProduct({
    required this.product,
    required this.nameNorm,
    required this.brandNorm,
    required this.barcode,
  });
}
