import 'package:hive/hive.dart';

/// A catalog product, custom recipe, or quick diary entry with nutrition data.
/// Hive TypeId: 1.
class FoodProduct {
  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double servingSizeGrams;
  final String? servingName;
  final bool isCustom;
  final bool isFavorite;
  final bool isQuickAdd;
  final List<RecipeIngredient> recipeIngredients;

  const FoodProduct({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.servingSizeGrams = 100.0,
    this.servingName,
    this.isCustom = false,
    this.isFavorite = false,
    this.isQuickAdd = false,
    this.recipeIngredients = const [],
  });

  bool get isRecipe => recipeIngredients.isNotEmpty;

  /// For recipes and quick entries, the stored nutrition base is one portion.
  bool get usesPortions => isRecipe || isQuickAdd;

  /// Calculates calories for a specific portion in grams.
  double caloriesForGrams(double grams) => caloriesPer100g * (grams / 100.0);

  /// Calculates protein in grams for a specific portion in grams.
  double proteinForGrams(double grams) => proteinPer100g * (grams / 100.0);

  /// Calculates carbohydrates in grams for a specific portion in grams.
  double carbsForGrams(double grams) => carbsPer100g * (grams / 100.0);

  /// Calculates fat in grams for a specific portion in grams.
  double fatForGrams(double grams) => fatPer100g * (grams / 100.0);

  /// Calculates fiber in grams for a specific portion in grams.
  double fiberForGrams(double grams) => (fiberPer100g ?? 0.0) * (grams / 100.0);

  /// Full brand + product name display label.
  String get fullDisplayName {
    if (brand != null && brand!.trim().isNotEmpty) {
      return '$name ($brand)';
    }
    return name;
  }

  FoodProduct copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? servingSizeGrams,
    String? servingName,
    bool? isCustom,
    bool? isFavorite,
    bool? isQuickAdd,
    List<RecipeIngredient>? recipeIngredients,
  }) {
    return FoodProduct(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      servingName: servingName ?? this.servingName,
      isCustom: isCustom ?? this.isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      isQuickAdd: isQuickAdd ?? this.isQuickAdd,
      recipeIngredients: recipeIngredients ?? this.recipeIngredients,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Manual Hive TypeAdapter for [FoodProduct] with TypeId 1.
class FoodProductAdapter extends TypeAdapter<FoodProduct> {
  @override
  final int typeId = 1;

  @override
  FoodProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return FoodProduct(
      id: fields[0] as String,
      barcode: fields[1] as String?,
      name: fields[2] as String,
      brand: fields[3] as String?,
      caloriesPer100g: (fields[4] as num).toDouble(),
      proteinPer100g: (fields[5] as num).toDouble(),
      carbsPer100g: (fields[6] as num).toDouble(),
      fatPer100g: (fields[7] as num).toDouble(),
      fiberPer100g: (fields[8] as num?)?.toDouble(),
      servingSizeGrams: (fields[9] as num?)?.toDouble() ?? 100.0,
      servingName: fields[10] as String?,
      isCustom: fields[11] as bool? ?? false,
      isFavorite: fields[12] as bool? ?? false,
      isQuickAdd: fields[13] as bool? ?? false,
      recipeIngredients: List.unmodifiable(
        (fields[14] as List?)?.cast<RecipeIngredient>() ?? const [],
      ),
    );
  }

  @override
  void write(BinaryWriter writer, FoodProduct obj) {
    writer
      ..writeByte(15) // Total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.brand)
      ..writeByte(4)
      ..write(obj.caloriesPer100g)
      ..writeByte(5)
      ..write(obj.proteinPer100g)
      ..writeByte(6)
      ..write(obj.carbsPer100g)
      ..writeByte(7)
      ..write(obj.fatPer100g)
      ..writeByte(8)
      ..write(obj.fiberPer100g)
      ..writeByte(9)
      ..write(obj.servingSizeGrams)
      ..writeByte(10)
      ..write(obj.servingName)
      ..writeByte(11)
      ..write(obj.isCustom)
      ..writeByte(12)
      ..write(obj.isFavorite)
      ..writeByte(13)
      ..write(obj.isQuickAdd)
      ..writeByte(14)
      ..write(obj.recipeIngredients);
  }
}

/// A product snapshot and the amount used to make one recipe portion.
class RecipeIngredient {
  final FoodProduct product;
  final double grams;

  const RecipeIngredient({required this.product, required this.grams});

  static ({
    double calories,
    double protein,
    double carbs,
    double fat,
    double fiber,
  }) totalNutrition(Iterable<RecipeIngredient> ingredients) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    for (final ingredient in ingredients) {
      final product = ingredient.product;
      final grams = ingredient.grams;
      calories += product.caloriesForGrams(grams);
      protein += product.proteinForGrams(grams);
      carbs += product.carbsForGrams(grams);
      fat += product.fatForGrams(grams);
      fiber += product.fiberForGrams(grams);
    }
    return (
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }
}

class RecipeIngredientAdapter extends TypeAdapter<RecipeIngredient> {
  @override
  final int typeId = 7;

  @override
  RecipeIngredient read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return RecipeIngredient(
      product: fields[0] as FoodProduct,
      grams: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, RecipeIngredient obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.grams);
  }
}
