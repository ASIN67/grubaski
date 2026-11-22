import 'package:uuid/uuid.dart';
import 'food_product.dart';

/// Single ingredient recognized by the AI within a meal dish.
class AiMealIngredient {
  final String name;
  final double weightGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const AiMealIngredient({
    required this.name,
    required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory AiMealIngredient.fromJson(Map<String, dynamic> json) {
    return AiMealIngredient(
      name: (json['name'] ?? 'Składnik').toString(),
      weightGrams: (json['weightGrams'] as num?)?.toDouble() ??
          (json['weight'] as num?)?.toDouble() ??
          50.0,
      calories: (json['calories'] as num?)?.toDouble() ??
          (json['kcal'] as num?)?.toDouble() ??
          0.0,
      protein: (json['protein'] as num?)?.toDouble() ??
          (json['proteinGrams'] as num?)?.toDouble() ??
          0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ??
          (json['carbsGrams'] as num?)?.toDouble() ??
          0.0,
      fat: (json['fat'] as num?)?.toDouble() ??
          (json['fatGrams'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weightGrams': weightGrams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

/// Comprehensive estimation result returned by Gemini AI.
class AiMealEstimationResult {
  final String mealName;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double estimatedWeightGrams;
  final List<AiMealIngredient> ingredients;
  final String? adviceOrNotes;
  final String? confidence;

  const AiMealEstimationResult({
    required this.mealName,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.estimatedWeightGrams,
    this.ingredients = const [],
    this.adviceOrNotes,
    this.confidence,
  });

  factory AiMealEstimationResult.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>?;
    final parsedIngredients = rawIngredients != null
        ? rawIngredients
            .whereType<Map<String, dynamic>>()
            .map((e) => AiMealIngredient.fromJson(e))
            .toList()
        : <AiMealIngredient>[];

    return AiMealEstimationResult(
      mealName: (json['mealName'] ?? json['name'] ?? 'Posiłek oszacowany przez AI')
          .toString(),
      calories: (json['calories'] as num?)?.toDouble() ??
          (json['kcal'] as num?)?.toDouble() ??
          0.0,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ??
          (json['protein'] as num?)?.toDouble() ??
          0.0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ??
          (json['carbs'] as num?)?.toDouble() ??
          0.0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ??
          (json['fat'] as num?)?.toDouble() ??
          0.0,
      estimatedWeightGrams:
          (json['estimatedWeightGrams'] as num?)?.toDouble() ??
              (json['weightGrams'] as num?)?.toDouble() ??
              100.0,
      ingredients: parsedIngredients,
      adviceOrNotes: json['adviceOrNotes']?.toString() ??
          json['notes']?.toString() ??
          json['description']?.toString(),
      confidence: json['confidence']?.toString() ?? 'Wysoka',
    );
  }

  /// Converts this AI estimated meal into a reusable [FoodProduct] with per-100g values
  /// so it can be stored directly in Hive and added into the user's diary.
  FoodProduct toFoodProduct({String? customId}) {
    final weight = estimatedWeightGrams > 0 ? estimatedWeightGrams : 100.0;
    final factor = 100.0 / weight;

    final cal100 = (calories * factor).round();
    final p100 = double.parse((proteinGrams * factor).toStringAsFixed(1));
    final c100 = double.parse((carbsGrams * factor).toStringAsFixed(1));
    final f100 = double.parse((fatGrams * factor).toStringAsFixed(1));

    return FoodProduct(
      id: customId ?? const Uuid().v4(),
      name: mealName,
      brand: 'AI Oszacowanie',
      caloriesPer100g: cal100.toDouble(),
      proteinPer100g: p100,
      carbsPer100g: c100,
      fatPer100g: f100,
      servingSizeGrams: weight,
      servingName: 'porcja',
      isCustom: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'mealName': mealName,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'estimatedWeightGrams': estimatedWeightGrams,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'adviceOrNotes': adviceOrNotes,
        'confidence': confidence,
      };
}
