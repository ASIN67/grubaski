import 'package:hive/hive.dart';
import 'food_product.dart';
import 'meal_type.dart';

/// Represents an individual logged food item in a specific meal on a given date.
/// Hive TypeId: 3.
class MealEntry {
  final String id;

  /// Format: 'YYYY-MM-DD' for high performance date-based indexing and queries.
  final String dateKey;
  final MealType mealType;
  final double grams;

  /// Snapshot of the product at log time, ensuring historic diary integrity
  /// even if product definition changes later.
  final FoodProduct product;

  const MealEntry({
    required this.id,
    required this.dateKey,
    required this.mealType,
    required this.grams,
    required this.product,
  });

  /// Actual weight, when known, independent of the stored nutrition scale.
  double? get weightGrams {
    if (product.isQuickAdd) return null;
    if (!product.isRecipe) return grams;
    final recipeWeight = product.recipeIngredients.fold<double>(
      0,
      (sum, ingredient) => sum + ingredient.grams,
    );
    return recipeWeight * (grams / 100);
  }

  /// Total calories in this meal entry.
  double get calories => product.caloriesForGrams(grams);

  /// Total protein in grams in this meal entry.
  double get protein => product.proteinForGrams(grams);

  /// Total carbohydrates in grams in this meal entry.
  double get carbs => product.carbsForGrams(grams);

  /// Total fat in grams in this meal entry.
  double get fat => product.fatForGrams(grams);

  /// Total fiber in grams in this meal entry.
  double get fiber => product.fiberForGrams(grams);

  MealEntry copyWith({
    String? id,
    String? dateKey,
    MealType? mealType,
    double? grams,
    FoodProduct? product,
  }) {
    return MealEntry(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      mealType: mealType ?? this.mealType,
      grams: grams ?? this.grams,
      product: product ?? this.product,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Manual Hive TypeAdapter for [MealEntry] with TypeId 3.
class MealEntryAdapter extends TypeAdapter<MealEntry> {
  @override
  final int typeId = 3;

  @override
  MealEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return MealEntry(
      id: fields[0] as String,
      dateKey: fields[1] as String,
      mealType: fields[2] as MealType,
      grams: (fields[3] as num).toDouble(),
      product: fields[4] as FoodProduct,
    );
  }

  @override
  void write(BinaryWriter writer, MealEntry obj) {
    writer
      ..writeByte(5) // Total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.mealType)
      ..writeByte(3)
      ..write(obj.grams)
      ..writeByte(4)
      ..write(obj.product);
  }
}
