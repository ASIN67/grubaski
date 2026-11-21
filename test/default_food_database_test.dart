import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/data/default_food_database.dart';

void main() {
  group('DefaultFoodDatabase Tests', () {
    test('contains over 1700 predefined Polish food products', () {
      expect(defaultFoodProducts.length, greaterThanOrEqualTo(1700));
      expect(defaultFoodProducts.length, equals(1755));
    });

    test('all product IDs are unique and non-empty', () {
      final ids = <String>{};
      for (final product in defaultFoodProducts) {
        expect(product.id, isNotEmpty);
        expect(product.id.startsWith('seed-'), isTrue);
        expect(
          ids.contains(product.id),
          isFalse,
          reason: 'Duplicate product ID found: ${product.id}',
        );
        ids.add(product.id);
      }
    });

    test('all products have valid names, serving info, and nutritional values', () {
      for (final product in defaultFoodProducts) {
        // Name and serving checks
        expect(product.name.trim(), isNotEmpty);
        expect(product.servingSizeGrams, greaterThan(0));
        expect(product.servingName, isNotNull);
        expect(product.servingName!.trim(), isNotEmpty);

        // Macronutrients checks
        expect(product.caloriesPer100g, greaterThanOrEqualTo(0));
        expect(product.proteinPer100g, greaterThanOrEqualTo(0));
        expect(product.carbsPer100g, greaterThanOrEqualTo(0));
        expect(product.fatPer100g, greaterThanOrEqualTo(0));
        if (product.fiberPer100g != null) {
          expect(product.fiberPer100g!, greaterThanOrEqualTo(0));
        }

        // Flag defaults
        expect(product.isCustom, isFalse);
        expect(product.isFavorite, isFalse);
        expect(product.isQuickAdd, isFalse);
        expect(product.recipeIngredients, isEmpty);
      }
    });

    test('barcodes if present are valid non-empty numeric strings', () {
      int barcodeCount = 0;
      for (final product in defaultFoodProducts) {
        if (product.barcode != null) {
          barcodeCount++;
          expect(product.barcode!.trim(), isNotEmpty);
          expect(RegExp(r'^\d+$').hasMatch(product.barcode!), isTrue);
        }
      }
      expect(barcodeCount, greaterThan(100));
    });

    test('contains essential popular Polish staple foods and brands', () {
      final names = defaultFoodProducts.map((p) => p.name.toLowerCase()).toList();
      final brands = defaultFoodProducts
          .where((p) => p.brand != null)
          .map((p) => p.brand!)
          .toSet();

      // Check staple foods presence
      expect(names.any((n) => n.contains('skyr')), isTrue);
      expect(names.any((n) => n.contains('twaróg')), isTrue);
      expect(names.any((n) => n.contains('pierś z kurczaka')), isTrue);
      expect(names.any((n) => n.contains('chleb')), isTrue);
      expect(names.any((n) => n.contains('owsiane')), isTrue);
      expect(names.any((n) => n.contains('kabanosy')), isTrue);
      expect(names.any((n) => n.contains('pomidor')), isTrue);
      expect(names.any((n) => n.contains('jabłko')), isTrue);
      expect(names.any((n) => n.contains('masło')), isTrue);
      expect(names.any((n) => n.contains('coca-cola')), isTrue);
      expect(names.any((n) => n.contains('ptasie mleczko')), isTrue);
      expect(names.any((n) => n.contains('wpc 80')), isTrue);

      // Check famous brands presence
      expect(brands.contains('Piątnica'), isTrue);
      expect(brands.contains('Mlekovita'), isTrue);
      expect(brands.contains('Kupiec'), isTrue);
      expect(brands.contains('Lubella'), isTrue);
      expect(brands.contains('Tarczyński'), isTrue);
      expect(brands.contains('Morliny'), isTrue);
      expect(brands.contains('Krakus'), isTrue);
      expect(brands.contains('KFD'), isTrue);
      expect(brands.contains('E.Wedel'), isTrue);
      expect(brands.contains('Winiary'), isTrue);
      expect(brands.contains('Lay\'s'), isTrue);
    });

    test('portion calculations work correctly on predefined products', () {
      final skyr = defaultFoodProducts.firstWhere(
        (p) => p.id == 'seed-nab-skyr-naturalny-piatnica',
      );
      expect(skyr.servingSizeGrams, equals(150.0));
      expect(skyr.caloriesForGrams(150.0), closeTo(97.5, 0.1));
      expect(skyr.proteinForGrams(150.0), closeTo(18.0, 0.1));
    });
  });
}
