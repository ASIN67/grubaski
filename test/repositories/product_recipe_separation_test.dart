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
    tempDir = await Directory.systemTemp.createTemp('recipe_separation_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FoodProductAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MealTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MealEntryAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(RecipeIngredientAdapter());
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

  test('recipes are excluded from product search and catalog listing', () async {
    final normalProduct = const FoodProduct(
      id: 'prod_1',
      name: 'Płatki owsiane górskie',
      caloriesPer100g: 370,
      proteinPer100g: 13,
      carbsPer100g: 65,
      fatPer100g: 7,
    );

    final recipeProductFromCommunity = const FoodProduct(
      id: 'recipe_community_123',
      name: '🍲 Owsianka z borówkami (porcja)',
      caloriesPer100g: 350,
      proteinPer100g: 15,
      carbsPer100g: 50,
      fatPer100g: 8,
      isCustom: true,
    );

    final localCustomRecipe = FoodProduct(
      id: 'recipe_local_456',
      name: 'Omlet białkowy z warzywami',
      caloriesPer100g: 220,
      proteinPer100g: 22,
      carbsPer100g: 5,
      fatPer100g: 10,
      isCustom: true,
      recipeIngredients: [
        RecipeIngredient(product: normalProduct, grams: 50),
      ],
    );

    await hive.foodProductsBox.put(normalProduct.id, normalProduct);
    await hive.foodProductsBox.put(recipeProductFromCommunity.id, recipeProductFromCommunity);
    await hive.foodProductsBox.put(localCustomRecipe.id, localCustomRecipe);

    final allLocal = repository.getAllLocalProducts();
    expect(allLocal.map((p) => p.id), contains('prod_1'));
    expect(allLocal.map((p) => p.id), isNot(contains('recipe_community_123')));
    expect(allLocal.map((p) => p.id), isNot(contains('recipe_local_456')));

    final searchResults = repository.searchLocalProducts('owsianka');
    expect(searchResults.map((p) => p.id), isNot(contains('recipe_community_123')));

    final customProducts = repository.getCustomProducts();
    expect(customProducts.map((p) => p.id), isNot(contains('recipe_community_123')));
    expect(customProducts.map((p) => p.id), isNot(contains('recipe_local_456')));
  });
}
