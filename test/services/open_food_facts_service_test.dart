import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/services/open_food_facts_service.dart';

void main() {
  late OpenFoodFactsService service;

  setUp(() {
    service = OpenFoodFactsService();
  });

  group('OpenFoodFactsService - Data Sanitization & Error Correction', () {
    test('discards corrupted items with dummy barcodes or garbage names', () async {
      // Dummy barcodes
      expect(await service.getProductByBarcode('12345678'), isNull);
      expect(await service.getProductByBarcode('00000000'), isNull);
      expect(await service.getProductByBarcode('1111111111111'), isNull);
      expect(await service.getProductByBarcode('123'), isNull);
    });

    test('recalculates calories when user entered 0 kcal or omitted kcal but gave macros', () {
      // In Open Food Facts, users sometimes omit calories but fill in macros
      final product = service.parseProductJsonForTesting({
        'code': '5901234567890',
        'product_name': 'Jogurt Naturalny',
        'brands': 'Piątnica',
        'nutriments': {
          'energy-kcal_100g': 0.0,
          'proteins_100g': 5.0, // 5 * 4 = 20 kcal
          'carbohydrates_100g': 4.0, // 4 * 4 = 16 kcal
          'fat_100g': 2.0, // 2 * 9 = 18 kcal
        },
      });

      expect(product, isNotNull);
      expect(product!.name, 'Jogurt Naturalny');
      expect(product.brand, 'Piątnica');
      expect(product.proteinPer100g, 5.0);
      expect(product.carbsPer100g, 4.0);
      expect(product.fatPer100g, 2.0);
      // Auto-corrected calories: 20 + 16 + 18 = 54 kcal (not 0!)
      expect(product.caloriesPer100g, 54.0);
    });

    test('auto-corrects when user entered kJ in the kcal field', () {
      // User entered 2150 in the kcal box for chocolate (which is actually ~2150 kJ / 514 kcal)
      final product = service.parseProductJsonForTesting({
        'code': '5901234567891',
        'product_name': 'Czekolada Gorzka',
        'brands': 'E. Wedel',
        'nutriments': {
          'energy-kcal_100g': 2150.0, // mistaken kJ value
          'proteins_100g': 7.0,
          'carbohydrates_100g': 45.0,
          'fat_100g': 34.0,
        },
      });

      expect(product, isNotNull);
      // Should be converted or recalculated to realistic kcal (~514 kcal, definitely < 900)
      expect(product!.caloriesPer100g, lessThan(600.0));
      expect(product.caloriesPer100g, greaterThan(450.0));
    });

    test('normalizes macros when slightly exceeding 100g due to rounding', () {
      final product = service.parseProductJsonForTesting({
        'code': '5901234567892',
        'product_name': 'Orzechy mix',
        'nutriments': {
          'energy-kcal_100g': 620.0,
          'proteins_100g': 22.0,
          'carbohydrates_100g': 25.0,
          'fat_100g': 65.0, // sum = 112g (over 105g)
        },
      });

      expect(product, isNotNull);
      final sum = product!.proteinPer100g + product.carbsPer100g + product.fatPer100g;
      expect(sum, closeTo(100.0, 1.0));
    });

    test('discards severely corrupted items where macros exceed 130g', () {
      final product = service.parseProductJsonForTesting({
        'code': '5901234567893',
        'product_name': 'Brednie dane',
        'nutriments': {
          'energy-kcal_100g': 1200.0,
          'proteins_100g': 80.0,
          'carbohydrates_100g': 90.0,
          'fat_100g': 70.0, // sum = 240g in 100g! Physically impossible
        },
      });

      expect(product, isNull);
    });

    test('filters out test products and dummy names', () {
      expect(
        service.parseProductJsonForTesting({
          'code': '5901234567894',
          'product_name': 'test',
          'nutriments': {'energy-kcal_100g': 100.0},
        }),
        isNull,
      );

      expect(
        service.parseProductJsonForTesting({
          'code': '5901234567895',
          'product_name': '...',
          'nutriments': {'energy-kcal_100g': 100.0},
        }),
        isNull,
      );
    });

    test('cleans duplicate brand prefix in product name', () {
      final product = service.parseProductJsonForTesting({
        'code': '5901234567896',
        'product_name': 'Mlekovita Mleko Polskie 3.2%',
        'brands': 'Mlekovita, Inne',
        'nutriments': {
          'energy-kcal_100g': 60.0,
          'proteins_100g': 3.2,
          'carbohydrates_100g': 4.7,
          'fat_100g': 3.2,
        },
      });

      expect(product, isNotNull);
      expect(product!.brand, 'Mlekovita');
      expect(product.name, 'Mleko Polskie 3.2%');
    });
  });
}
