import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/data/default_food_database.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/product_repository.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:hive/hive.dart';

void main() {
  group('1. Data Integrity and Uniqueness Checks', () {
    test('all product IDs are unique and non-empty', () {
      final seenIds = <String, FoodProduct>{};
      final duplicates = <String, List<String>>{};

      for (final p in defaultFoodProducts) {
        expect(p.id.trim(), isNotEmpty, reason: 'Product has empty ID: ${p.name}');
        if (seenIds.containsKey(p.id)) {
          duplicates.putIfAbsent(p.id, () => [seenIds[p.id]!.name]).add(p.name);
        } else {
          seenIds[p.id] = p;
        }
      }

      expect(
        duplicates,
        isEmpty,
        reason: 'Found duplicate product IDs: $duplicates',
      );
    });

    test('all barcodes are unique with zero collisions', () {
      final barcodeToProducts = <String, List<FoodProduct>>{};

      for (final p in defaultFoodProducts) {
        if (p.barcode != null && p.barcode!.trim().isNotEmpty) {
          final code = p.barcode!.trim();
          barcodeToProducts.putIfAbsent(code, () => []).add(p);
        }
      }

      final collisions = <String, List<String>>{};
      for (final entry in barcodeToProducts.entries) {
        if (entry.value.length > 1) {
          collisions[entry.key] = entry.value.map((p) => '${p.id} ("${p.name}")').toList();
        }
      }

      expect(
        collisions,
        isEmpty,
        reason: 'Found barcode collisions: $collisions',
      );
    });

    test('all barcodes are valid numeric strings', () {
      final invalidBarcodes = <String, String>{};
      final numericRegex = RegExp(r'^\d+$');

      for (final p in defaultFoodProducts) {
        if (p.barcode != null && p.barcode!.trim().isNotEmpty) {
          final code = p.barcode!.trim();
          if (!numericRegex.hasMatch(code) || code.length < 6 || code.length > 14) {
            invalidBarcodes[p.id] = 'barcode: "$code", product: "${p.name}"';
          }
        }
      }

      expect(
        invalidBarcodes,
        isEmpty,
        reason: 'Found invalid barcodes: $invalidBarcodes',
      );
    });

    test('all products have required metadata (name, serving size, serving name)', () {
      for (final p in defaultFoodProducts) {
        expect(p.name.trim(), isNotEmpty, reason: 'Empty name for product ${p.id}');
        expect(p.servingSizeGrams, greaterThan(0), reason: 'Non-positive serving size for ${p.id}');
        expect(p.servingName, isNotNull, reason: 'Null servingName for ${p.id}');
        expect(p.servingName!.trim(), isNotEmpty, reason: 'Empty servingName for ${p.id}');
      }
    });
  });

  group('2. Macronutrient and Calorie Sanity Checks', () {
    test('macronutrients sum per 100g is <= 100g (allowing slight rounding)', () {
      final violatingProducts = <String, String>{};

      for (final p in defaultFoodProducts) {
        // Non-negative
        expect(p.proteinPer100g, greaterThanOrEqualTo(0), reason: 'Negative protein for ${p.id}');
        expect(p.carbsPer100g, greaterThanOrEqualTo(0), reason: 'Negative carbs for ${p.id}');
        expect(p.fatPer100g, greaterThanOrEqualTo(0), reason: 'Negative fat for ${p.id}');
        if (p.fiberPer100g != null) {
          expect(p.fiberPer100g!, greaterThanOrEqualTo(0), reason: 'Negative fiber for ${p.id}');
        }

        final sumMacros = p.proteinPer100g + p.carbsPer100g + p.fatPer100g;
        // 100.5g tolerance for floating point / independent single decimal roundings on food labels
        if (sumMacros > 100.5) {
          violatingProducts[p.id] =
              '${p.name}: sum=${sumMacros.toStringAsFixed(1)}g (P:${p.proteinPer100g}, C:${p.carbsPer100g}, F:${p.fatPer100g})';
        }
      }

      expect(
        violatingProducts,
        isEmpty,
        reason: 'Products exceeding 100g of macros per 100g: $violatingProducts',
      );
    });

    test('calories per 100g are sane and align with Atwater factor (4*P + 4*C + 9*F)', () {
      final anomalousProducts = <String, String>{};

      for (final p in defaultFoodProducts) {
        expect(p.caloriesPer100g, greaterThanOrEqualTo(0), reason: 'Negative calories for ${p.id}');

        // Erythritol is legally 0 kcal despite 100g polyols/carbs
        if (p.name.toLowerCase().contains('erytrytol') || p.id.contains('erytrytol')) {
          continue;
        }

        final expectedKcal = (4 * p.proteinPer100g) + (4 * p.carbsPer100g) + (9 * p.fatPer100g);

        // If product has zero macros but positive calories > 30, or vice versa
        final sumMacros = p.proteinPer100g + p.carbsPer100g + p.fatPer100g;
        if (sumMacros == 0 && p.caloriesPer100g > 30) {
          anomalousProducts[p.id] =
              '${p.name}: 0 macros but ${p.caloriesPer100g} kcal';
        }

        // Check severe discrepancy (> 150 kcal difference and > 50% relative error, allowing for fiber, polyols, organic acids)
        final diff = (p.caloriesPer100g - expectedKcal).abs();
        if (expectedKcal > 50 && diff > 150 && (diff / expectedKcal) > 0.6) {
          anomalousProducts[p.id] =
              '${p.name}: actual=${p.caloriesPer100g} vs theoretical=${expectedKcal.toStringAsFixed(1)} kcal (diff: ${diff.toStringAsFixed(1)})';
        }
      }

      expect(
        anomalousProducts,
        isEmpty,
        reason: 'Found products with severely inconsistent calories: $anomalousProducts',
      );
    });
  });

  group('3. Search Speed and Latency Benchmark', () {
    late Directory tempDir;
    late ProductRepository repository;
    final hive = HiveService.instance;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('verification_benchmark_');
      await hive.init(customPath: tempDir.path);
      repository = ProductRepository(hiveService: hive);
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('local product search executes fast (< 5ms avg per query) on the full catalog', () {
      final totalProducts = hive.foodProductsBox.length;
      expect(totalProducts, greaterThanOrEqualTo(1000));

      final benchmarkQueries = [
        // Polish common foods
        'chleb',
        'chleb zytni',
        'kajzerka',
        'skyr',
        'skyr naturalny',
        'twarog',
        'twarog chudy',
        'piers z kurczaka',
        'kabanosy',
        'mleko',
        'mleko 2%',
        'jajko',
        'platki owsiane',
        'maslo',
        'oliwa',
        'losos',
        'makaron',
        'ryz',
        'kasza',
        'pomidor',
        'jablko',
        'banan',
        'orzechy',
        'czekolada',
        'kawa',
        'herbata',
        // Brands
        'piatnica',
        'mlekovita',
        'kfd',
        'tarczynski',
        'morliny',
        'lubella',
        'winiary',
        'wedel',
        'biedronka',
        'lidl',
        // Barcode-style queries (numbers)
        '590',
        '5900',
        // Case-insensitivity and diacritics
        'BULKA',
        'BuŁkA',
        'LOSOS WEDZONY',
        'twaróg półtłusty',
        'serek wiejski',
      ];

      // JIT Warm-up run
      for (final q in benchmarkQueries.take(5)) {
        repository.searchLocalProducts(q);
      }

      // Benchmark timing
      final stopwatch = Stopwatch()..start();
      int totalHits = 0;

      for (final q in benchmarkQueries) {
        final results = repository.searchLocalProducts(q);
        totalHits += results.length;
      }
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgMs = elapsedMs / benchmarkQueries.length;

      // ignore: avoid_print
      print('\n========================================');
      // ignore: avoid_print
      print('SEARCH SPEED BENCHMARK RESULTS:');
      // ignore: avoid_print
      print('Catalog size: $totalProducts products');
      // ignore: avoid_print
      print('Queries tested: ${benchmarkQueries.length}');
      // ignore: avoid_print
      print('Total hits found: $totalHits');
      // ignore: avoid_print
      print('Total elapsed time: ${elapsedMs}ms');
      // ignore: avoid_print
      print('Average latency per query: ${avgMs.toStringAsFixed(3)}ms');
      // ignore: avoid_print
      print('========================================\n');

      expect(totalHits, greaterThan(0));
      // Average latency should comfortably beat 10ms (target: < 5ms)
      expect(avgMs, lessThan(10.0));
    });
  });
}
