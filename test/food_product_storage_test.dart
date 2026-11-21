import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/food_product.dart';
import 'package:hive/hive.dart';

void main() {
  test('Hive restores legacy products and round-trips recipe ingredients',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('food_storage_test_');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    Hive.registerAdapter(_LegacyFoodProductAdapter());

    const boxName = 'products';
    const oats = FoodProduct(
      id: 'oats',
      barcode: '5901234567890',
      name: 'Płatki owsiane',
      brand: 'Przykład',
      caloriesPer100g: 370,
      proteinPer100g: 13.5,
      carbsPer100g: 61.3,
      fatPer100g: 7,
      fiberPer100g: 9.7,
      servingSizeGrams: 40,
      servingName: 'Porcja',
      isCustom: true,
    );

    var box = await Hive.openBox<FoodProduct>(boxName);
    await box.put(oats.id, oats);
    await box.close();

    Hive.resetAdapters();
    Hive.registerAdapter(FoodProductAdapter());
    Hive.registerAdapter(RecipeIngredientAdapter());
    box = await Hive.openBox<FoodProduct>(boxName);
    final legacy = box.get(oats.id)!;
    expect(legacy.id, oats.id);
    expect(legacy.barcode, oats.barcode);
    expect(legacy.name, oats.name);
    expect(legacy.brand, oats.brand);
    expect(legacy.caloriesPer100g, oats.caloriesPer100g);
    expect(legacy.proteinPer100g, oats.proteinPer100g);
    expect(legacy.carbsPer100g, oats.carbsPer100g);
    expect(legacy.fatPer100g, oats.fatPer100g);
    expect(legacy.fiberPer100g, oats.fiberPer100g);
    expect(legacy.servingSizeGrams, oats.servingSizeGrams);
    expect(legacy.servingName, oats.servingName);
    expect(legacy.isCustom, isTrue);
    expect(legacy.isFavorite, isFalse);
    expect(legacy.isQuickAdd, isFalse);
    expect(legacy.recipeIngredients, isEmpty);

    const recipe = FoodProduct(
      id: 'recipe',
      name: 'Moja owsianka',
      caloriesPer100g: 185,
      proteinPer100g: 6.75,
      carbsPer100g: 30.65,
      fatPer100g: 3.5,
      fiberPer100g: 4.85,
      isCustom: true,
      isFavorite: true,
      recipeIngredients: [RecipeIngredient(product: oats, grams: 50)],
    );
    const quickAdd = FoodProduct(
      id: 'quick',
      name: 'Lunch na mieście',
      caloriesPer100g: 750,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
      isQuickAdd: true,
    );

    await box.putAll({recipe.id: recipe, quickAdd.id: quickAdd});
    await box.close();
    box = await Hive.openBox<FoodProduct>(boxName);

    final savedRecipe = box.get(recipe.id)!;
    expect(savedRecipe.isFavorite, isTrue);
    expect(savedRecipe.isRecipe, isTrue);
    expect(savedRecipe.usesPortions, isTrue);
    final ingredient = savedRecipe.recipeIngredients.single;
    expect(ingredient.product.name, oats.name);
    expect(ingredient.product.caloriesPer100g, 370);
    expect(ingredient.product.fiberPer100g, 9.7);
    expect(ingredient.grams, 50);
    final totals =
        RecipeIngredient.totalNutrition(savedRecipe.recipeIngredients);
    expect(totals.calories, 185);
    expect(totals.fiber, 4.85);

    final savedQuickAdd = box.get(quickAdd.id)!;
    expect(savedQuickAdd.isQuickAdd, isTrue);
    expect(savedQuickAdd.usesPortions, isTrue);
    expect(savedQuickAdd.isRecipe, isFalse);
    expect(savedQuickAdd.caloriesPer100g, 750);
  });
}

/// The field layout written to Hive before favorites, quick adds and recipes.
class _LegacyFoodProductAdapter extends TypeAdapter<FoodProduct> {
  @override
  final int typeId = 1;

  @override
  FoodProduct read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, FoodProduct product) {
    final fields = [
      product.id,
      product.barcode,
      product.name,
      product.brand,
      product.caloriesPer100g,
      product.proteinPer100g,
      product.carbsPer100g,
      product.fatPer100g,
      product.fiberPer100g,
      product.servingSizeGrams,
      product.servingName,
      product.isCustom,
    ];
    writer.writeByte(fields.length);
    for (final (index, value) in fields.indexed) {
      writer
        ..writeByte(index)
        ..write(value);
    }
  }
}
