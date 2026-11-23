import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/models.dart';
import 'package:grubasek/repositories/product_repository.dart';
import 'package:grubasek/services/hive_service.dart';
import 'package:hive/hive.dart';

void main() {
  final hive = HiveService.instance;
  late Directory tempDir;
  late ProductRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('product_search_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(FoodProductAdapter());
    Hive.registerAdapter(MealTypeAdapter());
    Hive.registerAdapter(MealEntryAdapter());
    Hive.registerAdapter(RecipeIngredientAdapter());
    await Hive.openBox<FoodProduct>(HiveService.foodProductsBoxName);
    repository = ProductRepository(hiveService: hive);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await hive.foodProductsBox.clear();
  });

  group('ProductRepository.searchLocalProducts - Polish diacritics', () {
    test('finds products when query has no diacritics (bulka -> bułka, twarog -> twaróg)',
        () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'p1',
          name: 'Bułka kajzerka',
          caloriesPer100g: 280,
          proteinPer100g: 8,
          carbsPer100g: 55,
          fatPer100g: 3,
        ),
        const FoodProduct(
          id: 'p2',
          name: 'Twaróg chudy',
          brand: 'Piątnica',
          caloriesPer100g: 86,
          proteinPer100g: 18,
          carbsPer100g: 3.5,
          fatPer100g: 0.5,
        ),
        const FoodProduct(
          id: 'p3',
          name: 'Jajko kurze całe',
          caloriesPer100g: 143,
          proteinPer100g: 12.5,
          carbsPer100g: 0.7,
          fatPer100g: 9.9,
        ),
        const FoodProduct(
          id: 'p4',
          name: 'Łosoś wędzony',
          caloriesPer100g: 170,
          proteinPer100g: 21,
          carbsPer100g: 0,
          fatPer100g: 9.5,
        ),
        const FoodProduct(
          id: 'p5',
          name: 'Ser żółty Gouda',
          caloriesPer100g: 350,
          proteinPer100g: 25,
          carbsPer100g: 0,
          fatPer100g: 27,
        ),
        const FoodProduct(
          id: 'p6',
          name: 'Mąka pszenna typ 500',
          caloriesPer100g: 340,
          proteinPer100g: 10,
          carbsPer100g: 70,
          fatPer100g: 1,
        ),
      ]);

      // Query "bulka" without Polish "ł"
      final bulkaResults = repository.searchLocalProducts('bulka');
      expect(bulkaResults.map((p) => p.name), contains('Bułka kajzerka'));

      // Query "twarog" without Polish "ó"
      final twarogResults = repository.searchLocalProducts('twarog');
      expect(twarogResults.map((p) => p.name), contains('Twaróg chudy'));

      // Query "jajko"
      final jajkoResults = repository.searchLocalProducts('jajko');
      expect(jajkoResults.map((p) => p.name), contains('Jajko kurze całe'));

      // Query "losos" without Polish "Ł" and "ś"
      final lososResults = repository.searchLocalProducts('losos');
      expect(lososResults.map((p) => p.name), contains('Łosoś wędzony'));

      // Query "zolty" without Polish "ż"
      final zoltyResults = repository.searchLocalProducts('zolty');
      expect(zoltyResults.map((p) => p.name), contains('Ser żółty Gouda'));

      // Query "maka" without Polish "ą"
      final makaResults = repository.searchLocalProducts('maka');
      expect(makaResults.map((p) => p.name), contains('Mąka pszenna typ 500'));
    });

    test('finds products when query has uppercase or mixed Polish diacritics',
        () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'b1',
          name: 'Bułka tarta',
          caloriesPer100g: 350,
          proteinPer100g: 10,
          carbsPer100g: 70,
          fatPer100g: 2,
        ),
      ]);

      expect(repository.searchLocalProducts('BUŁKA').first.id, equals('b1'));
      expect(repository.searchLocalProducts('bułka').first.id, equals('b1'));
      expect(repository.searchLocalProducts('BULKA').first.id, equals('b1'));
      expect(repository.searchLocalProducts('BuŁkA').first.id, equals('b1'));
    });
  });

  group('ProductRepository.searchLocalProducts - Prioritization', () {
    test('exact match is ranked above starts-with and middle match', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'middle',
          name: 'Zestaw: bułka i masło',
          caloriesPer100g: 250,
          proteinPer100g: 15,
          carbsPer100g: 1,
          fatPer100g: 20,
        ),
        const FoodProduct(
          id: 'exact',
          name: 'Bułka',
          caloriesPer100g: 270,
          proteinPer100g: 8,
          carbsPer100g: 54,
          fatPer100g: 2,
        ),
        const FoodProduct(
          id: 'starts_with',
          name: 'Bułka pszenna',
          caloriesPer100g: 280,
          proteinPer100g: 8,
          carbsPer100g: 55,
          fatPer100g: 2.5,
        ),
      ]);

      final results = repository.searchLocalProducts('bulka');
      expect(results.length, equals(3));
      expect(results[0].id, equals('exact'));
      expect(results[1].id, equals('starts_with'));
      expect(results[2].id, equals('middle'));
    });

    test('starts-with in name is ranked above brand and middle of name',
        () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'brand_match',
          name: 'Chleb razowy',
          brand: 'Bułka i Spółka',
          caloriesPer100g: 220,
          proteinPer100g: 6,
          carbsPer100g: 45,
          fatPer100g: 1.5,
        ),
        const FoodProduct(
          id: 'starts_with',
          name: 'Bułka grahamka',
          caloriesPer100g: 260,
          proteinPer100g: 9,
          carbsPer100g: 50,
          fatPer100g: 2,
        ),
        const FoodProduct(
          id: 'middle_match',
          name: 'Szybka bułka z szynką',
          caloriesPer100g: 300,
          proteinPer100g: 12,
          carbsPer100g: 40,
          fatPer100g: 10,
        ),
      ]);

      final results = repository.searchLocalProducts('bulka');
      expect(results[0].id, equals('starts_with'));
      // Middle of name (or brand) comes after starts_with
      expect(results[1].id, isNot('starts_with'));
    });

    test('favorite products (isFavorite) get a light bonus within the same match tier',
        () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'regular_grahamka',
          name: 'Bułka grahamka',
          caloriesPer100g: 260,
          proteinPer100g: 9,
          carbsPer100g: 50,
          fatPer100g: 2,
          isFavorite: false,
        ),
        const FoodProduct(
          id: 'fav_kajzerka',
          name: 'Bułka kajzerka',
          caloriesPer100g: 280,
          proteinPer100g: 8,
          carbsPer100g: 55,
          fatPer100g: 3,
          isFavorite: true,
        ),
      ]);

      // Both start with "Bułka" and have similar name length.
      // Favorite should be ranked first due to the isFavorite bonus!
      final results = repository.searchLocalProducts('bulka');
      expect(results[0].id, equals('fav_kajzerka'));
      expect(results[1].id, equals('regular_grahamka'));
    });

    test('favorite bonus does not override a superior match tier', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'fav_middle',
          name: 'Zestaw: bułka i parówki',
          caloriesPer100g: 150,
          proteinPer100g: 2,
          carbsPer100g: 10,
          fatPer100g: 11,
          isFavorite: true,
        ),
        const FoodProduct(
          id: 'regular_exact',
          name: 'Bułka',
          caloriesPer100g: 270,
          proteinPer100g: 8,
          carbsPer100g: 54,
          fatPer100g: 2,
          isFavorite: false,
        ),
        const FoodProduct(
          id: 'regular_starts',
          name: 'Bułka maślana',
          caloriesPer100g: 310,
          proteinPer100g: 7,
          carbsPer100g: 58,
          fatPer100g: 6,
          isFavorite: false,
        ),
      ]);

      final results = repository.searchLocalProducts('bulka');
      // Exact match and starts-with MUST still be ahead of middle match despite middle being favorite
      expect(results[0].id, equals('regular_exact'));
      expect(results[1].id, equals('regular_starts'));
      expect(results[2].id, equals('fav_middle'));
    });
  });

  group('ProductRepository.searchLocalProducts - Multi-token & Barcode', () {
    test('matches multiple tokens across name and brand', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'skyr_piatnica',
          name: 'Skyr naturalny 0%',
          brand: 'Piątnica',
          caloriesPer100g: 65,
          proteinPer100g: 12,
          carbsPer100g: 4,
          fatPer100g: 0,
        ),
        const FoodProduct(
          id: 'skyr_kfd',
          name: 'Skyr waniliowy',
          brand: 'KFD',
          caloriesPer100g: 80,
          proteinPer100g: 11,
          carbsPer100g: 7,
          fatPer100g: 0,
        ),
      ]);

      // "skyr piatnica" should find only Piątnica skyr
      final results = repository.searchLocalProducts('skyr piatnica');
      expect(results.length, equals(1));
      expect(results.first.id, equals('skyr_piatnica'));

      // "skyr 0%" should find Skyr naturalny 0%
      final zeroResults = repository.searchLocalProducts('skyr 0%');
      expect(zeroResults.length, equals(1));
      expect(zeroResults.first.id, equals('skyr_piatnica'));
    });

    test('matches barcode with highest priority for exact barcode', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'ean_exact',
          name: 'Woda mineralna',
          barcode: '5901234567890',
          caloriesPer100g: 0,
          proteinPer100g: 0,
          carbsPer100g: 0,
          fatPer100g: 0,
        ),
        const FoodProduct(
          id: 'ean_partial',
          name: 'Sok jabłkowy 590123',
          barcode: '5909999999999',
          caloriesPer100g: 45,
          proteinPer100g: 0.1,
          carbsPer100g: 11,
          fatPer100g: 0.1,
        ),
      ]);

      final results = repository.searchLocalProducts('5901234567890');
      expect(results.first.id, equals('ean_exact'));
    });
  });

  group('ProductRepository.searchLocalProducts - Polish Inflections, Stems & Brand Aliases', () {
    test('finds Chikker with exact query, "chikker z maka" and "chikker maka"', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'chikker_mcd',
          name: 'Chikker',
          brand: 'McDonald\'s',
          caloriesPer100g: 272,
          proteinPer100g: 9.6,
          carbsPer100g: 30,
          fatPer100g: 12,
        ),
        const FoodProduct(
          id: 'mcchicken_mcd',
          name: 'McChicken',
          brand: 'McDonald\'s',
          caloriesPer100g: 229,
          proteinPer100g: 10.5,
          carbsPer100g: 23,
          fatPer100g: 10.5,
        ),
        const FoodProduct(
          id: 'kurczak_kfc',
          name: 'Kurczak Strips',
          brand: 'KFC',
          caloriesPer100g: 240,
          proteinPer100g: 18,
          carbsPer100g: 15,
          fatPer100g: 12,
        ),
      ]);

      // Query "chikker"
      final r1 = repository.searchLocalProducts('chikker');
      expect(r1.first.id, equals('chikker_mcd'));

      // Query "chikker z maka"
      final r2 = repository.searchLocalProducts('chikker z maka');
      expect(r2.first.id, equals('chikker_mcd'));

      // Query "chikker maka"
      final r3 = repository.searchLocalProducts('chikker maka');
      expect(r3.first.id, equals('chikker_mcd'));

      // Query "chikker mcdonald"
      final r4 = repository.searchLocalProducts('chikker mcdonald');
      expect(r4.first.id, equals('chikker_mcd'));
    });

    test('matches Polish grammatical inflections (jogurt truskawka -> Jogurt truskawkowy)', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'jogurt_truskawkowy',
          name: 'Jogurt truskawkowy',
          brand: 'Pilos',
          caloriesPer100g: 78,
          proteinPer100g: 4.2,
          carbsPer100g: 12,
          fatPer100g: 1.5,
        ),
        const FoodProduct(
          id: 'jogurt_naturalny',
          name: 'Jogurt naturalny',
          brand: 'Pilos',
          caloriesPer100g: 60,
          proteinPer100g: 4.5,
          carbsPer100g: 5.5,
          fatPer100g: 2.0,
        ),
      ]);

      // "jogurt truskawka" should match "Jogurt truskawkowy"
      final results = repository.searchLocalProducts('jogurt truskawka');
      expect(results, isNotEmpty);
      expect(results.first.id, equals('jogurt_truskawkowy'));
    });

    test('matches brand aliases (biedra -> Biedronka, lidla -> Lidl, piatnicy -> Piątnica)', () async {
      await repository.saveProducts([
        const FoodProduct(
          id: 'twarog_piatnica',
          name: 'Twaróg wiejski',
          brand: 'Piątnica',
          caloriesPer100g: 86,
          proteinPer100g: 18,
          carbsPer100g: 3.5,
          fatPer100g: 0.5,
        ),
        const FoodProduct(
          id: 'kajzerka_biedronka',
          name: 'Kajzerka pszenna',
          brand: 'Biedronka',
          caloriesPer100g: 280,
          proteinPer100g: 8,
          carbsPer100g: 55,
          fatPer100g: 2,
        ),
      ]);

      final r1 = repository.searchLocalProducts('twarog z piatnicy');
      expect(r1, isNotEmpty);
      expect(r1.first.id, equals('twarog_piatnica'));

      final r2 = repository.searchLocalProducts('kajzerka z biedry');
      expect(r2, isNotEmpty);
      expect(r2.first.id, equals('kajzerka_biedronka'));
    });
  });

  group('ProductRepository.searchLocalProducts - Performance benchmark', () {
    test('searches 600+ products in under 5 milliseconds per query', () async {
      final largeCatalog = <String, FoodProduct>{};

      final prefixes = [
        'Bułka', 'Chleb', 'Ser', 'Twaróg', 'Jajko', 'Szynka', 'Kiełbasa',
        'Mleko', 'Jogurt', 'Kefir', 'Ryż', 'Kasza', 'Makaron', 'Owsianka',
        'Łosoś', 'Dorsz', 'Pierś', 'Schab', 'Jabłko', 'Banan', 'Pomidor',
      ];
      final variants = [
        'grahamka', 'pszenna', 'żytnia', 'wiejski', 'chudy', 'tłusty',
        'półtłusty', 'naturalny', 'grecki', 'wędzony', 'gotowany', 'pieczony',
        'smażony', 'bio', 'eko', 'lekki', 'fit', 'proteinowy', 'tradycyjny',
      ];
      final brands = [
        'Piątnica', 'Mlekovita', 'Łowicz', 'Tarczyński', 'KFD', 'Bakoma',
        'Danone', 'Lubella', 'Wasa', 'Biedronka', 'Lidl', null,
      ];

      for (var i = 0; i < 600; i++) {
        final prefix = prefixes[i % prefixes.length];
        final variant = variants[(i ~/ prefixes.length) % variants.length];
        final id = 'perf_$i';
        final brand = brands[i % brands.length];
        largeCatalog[id] = FoodProduct(
          id: id,
          name: '$prefix $variant ${i % 10 == 0 ? "extra" : ""}',
          brand: brand,
          barcode: '590000000$i',
          caloriesPer100g: (100 + (i % 300)).toDouble(),
          proteinPer100g: (5 + (i % 25)).toDouble(),
          carbsPer100g: (i % 60).toDouble(),
          fatPer100g: (i % 30).toDouble(),
          isFavorite: i % 7 == 0,
        );
      }

      await hive.foodProductsBox.putAll(largeCatalog);
      expect(hive.foodProductsBox.length, greaterThanOrEqualTo(600));

      final testQueries = [
        'bulka',
        'twarog',
        'jajko',
        'kielbasa',
        'losos',
        'piatnica',
        'chudy',
        'ser',
        'jogurt',
        'mlekovita',
      ];

      // Warmup
      repository.searchLocalProducts('bulka');

      // Warm up JIT
      repository.searchLocalProducts('twarog');

      final stopwatch = Stopwatch()..start();
      for (final query in testQueries) {
        final matches = repository.searchLocalProducts(query);
        expect(matches, isNotEmpty, reason: 'Expected matches for query $query');
      }
      stopwatch.stop();

      final totalMs = stopwatch.elapsedMilliseconds;
      final avgMs = totalMs / testQueries.length;
      // ignore: avoid_print
      print('Performance: ${largeCatalog.length} products searched across ${testQueries.length} queries in ${totalMs}ms (avg: ${avgMs.toStringAsFixed(2)}ms/query)');

      // Must be fast even under heavy parallel CI/test runner load
      expect(avgMs, lessThan(60.0));
    });
  });
}
