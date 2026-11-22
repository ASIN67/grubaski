import 'food_product.dart';

class RecipeIngredientItem {
  final String name;
  final String amount;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const RecipeIngredientItem({
    required this.name,
    required this.amount,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory RecipeIngredientItem.fromMap(Map<String, dynamic> map) {
    return RecipeIngredientItem(
      name: map['name']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '',
      calories: (map['calories'] is num) ? (map['calories'] as num).toInt() : 0,
      protein: (map['protein'] is num) ? (map['protein'] as num).toDouble() : 0.0,
      carbs: (map['carbs'] is num) ? (map['carbs'] as num).toDouble() : 0.0,
      fat: (map['fat'] is num) ? (map['fat'] as num).toDouble() : 0.0,
    );
  }
}

class CommunityRecipe {
  final String id;
  final String title;
  final String description;
  final String category;
  final int prepTimeMinutes;
  final int servings;
  final int caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final List<RecipeIngredientItem> ingredients;
  final List<String> steps;
  final String authorName;
  final String? authorId;
  final bool isVerified;
  final DateTime createdAt;

  const CommunityRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.prepTimeMinutes,
    this.servings = 1,
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    required this.ingredients,
    required this.steps,
    this.authorName = 'Grubasek Społeczność',
    this.authorId,
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'prep_time_minutes': prepTimeMinutes,
      'servings': servings,
      'calories_per_serving': caloriesPerServing,
      'protein_per_serving': proteinPerServing,
      'carbs_per_serving': carbsPerServing,
      'fat_per_serving': fatPerServing,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'steps': steps,
      'author_name': authorName,
      'author_id': authorId,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunityRecipe.fromMap(Map<String, dynamic> map) {
    List<RecipeIngredientItem> parsedIngredients = [];
    if (map['ingredients'] != null && map['ingredients'] is List) {
      for (final item in map['ingredients'] as List) {
        if (item is Map) {
          parsedIngredients.add(
            RecipeIngredientItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    List<String> parsedSteps = [];
    if (map['steps'] != null && map['steps'] is List) {
      for (final step in map['steps'] as List) {
        if (step != null) {
          parsedSteps.add(step.toString());
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return CommunityRecipe(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Obiad',
      prepTimeMinutes: (map['prep_time_minutes'] is num)
          ? (map['prep_time_minutes'] as num).toInt()
          : 20,
      servings: (map['servings'] is num) ? (map['servings'] as num).toInt() : 1,
      caloriesPerServing: (map['calories_per_serving'] is num)
          ? (map['calories_per_serving'] as num).toInt()
          : 0,
      proteinPerServing: (map['protein_per_serving'] is num)
          ? (map['protein_per_serving'] as num).toDouble()
          : 0.0,
      carbsPerServing: (map['carbs_per_serving'] is num)
          ? (map['carbs_per_serving'] as num).toDouble()
          : 0.0,
      fatPerServing: (map['fat_per_serving'] is num)
          ? (map['fat_per_serving'] as num).toDouble()
          : 0.0,
      ingredients: parsedIngredients,
      steps: parsedSteps,
      authorName: map['author_name']?.toString() ?? 'Grubasek Społeczność',
      authorId: map['author_id']?.toString(),
      isVerified: map['is_verified'] == true,
      createdAt: parsedDate,
    );
  }

  FoodProduct toFoodProduct() {
    return FoodProduct(
      id: 'recipe_$id',
      name: '🍲 $title (porcja)',
      brand: 'Przepis: $authorName',
      caloriesPer100g: caloriesPerServing.toDouble(),
      proteinPer100g: proteinPerServing,
      carbsPer100g: carbsPerServing,
      fatPer100g: fatPerServing,
      servingSizeGrams: 100.0,
      servingName: 'porcja',
      isCustom: true,
    );
  }
}
