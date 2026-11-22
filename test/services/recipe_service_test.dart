import 'package:flutter_test/flutter_test.dart';
import 'package:grubasek/models/recipe_model.dart';
import 'package:grubasek/services/recipe_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('RecipeIngredientItem Model Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      const item = RecipeIngredientItem(
        name: 'Pierś z kurczaka',
        amount: '200g',
        calories: 220,
        protein: 43.0,
        carbs: 0.0,
        fat: 4.0,
      );

      final map = item.toMap();
      expect(map['name'], 'Pierś z kurczaka');
      expect(map['amount'], '200g');
      expect(map['calories'], 220);
      expect(map['protein'], 43.0);

      final fromMap = RecipeIngredientItem.fromMap(map);
      expect(fromMap.name, 'Pierś z kurczaka');
      expect(fromMap.amount, '200g');
      expect(fromMap.calories, 220);
      expect(fromMap.protein, 43.0);
      expect(fromMap.carbs, 0.0);
      expect(fromMap.fat, 4.0);
    });

    test('fromMap handles null and missing fields gracefully', () {
      final fromMap = RecipeIngredientItem.fromMap({});
      expect(fromMap.name, '');
      expect(fromMap.amount, '');
      expect(fromMap.calories, 0);
      expect(fromMap.protein, 0.0);
      expect(fromMap.carbs, 0.0);
      expect(fromMap.fat, 0.0);
    });
  });

  group('CommunityRecipe Model Tests', () {
    test('toMap and fromMap parse full recipe object accurately', () {
      final now = DateTime.now();
      final recipe = CommunityRecipe(
        id: 'test-rec-1',
        title: 'Omlet białkowy z warzywami',
        description: 'Szybki i sycący omlet na redukcję',
        category: 'Śniadanie',
        prepTimeMinutes: 12,
        servings: 1,
        caloriesPerServing: 320,
        proteinPerServing: 35.0,
        carbsPerServing: 10.0,
        fatPerServing: 12.0,
        ingredients: [
          const RecipeIngredientItem(
            name: 'Jajka',
            amount: '3 sztuki',
            calories: 210,
            protein: 18.0,
            carbs: 1.5,
            fat: 15.0,
          ),
          const RecipeIngredientItem(
            name: 'Szpinak',
            amount: '50g',
            calories: 12,
            protein: 1.4,
            carbs: 0.8,
            fat: 0.2,
          ),
        ],
        steps: [
          'Rozbij jajka w misce i roztrzep widelcem.',
          'Podsmaż szpinak na patelni.',
          'Wlej masę jajeczną i smaż pod przykryciem 5 minut.',
        ],
        authorName: 'Trener Michał',
        isVerified: true,
        createdAt: now,
      );

      final map = recipe.toMap();
      expect(map['id'], 'test-rec-1');
      expect(map['title'], 'Omlet białkowy z warzywami');
      expect(map['category'], 'Śniadanie');
      expect(map['prep_time_minutes'], 12);
      expect(map['servings'], 1);
      expect(map['calories_per_serving'], 320);
      expect(map['protein_per_serving'], 35.0);
      expect(map['is_verified'], isTrue);

      final restored = CommunityRecipe.fromMap(map);
      expect(restored.id, 'test-rec-1');
      expect(restored.title, 'Omlet białkowy z warzywami');
      expect(restored.ingredients.length, 2);
      expect(restored.steps.length, 3);
      expect(restored.steps[0], 'Rozbij jajka w misce i roztrzep widelcem.');
      expect(restored.isVerified, isTrue);
    });

    test('toFoodProduct converts recipe to loggable FoodProduct', () {
      final recipe = CommunityRecipe(
        id: 'rec_555',
        title: 'Bowl z łososiem',
        description: 'Zdrowa micha pełna kwasów omega-3',
        category: 'Obiad',
        prepTimeMinutes: 20,
        caloriesPerServing: 520,
        proteinPerServing: 38.0,
        carbsPerServing: 45.0,
        fatPerServing: 18.0,
        ingredients: const [],
        steps: const [],
        createdAt: DateTime.now(),
      );

      final product = recipe.toFoodProduct();
      expect(product.id, 'recipe_rec_555');
      expect(product.name, '🍲 Bowl z łososiem (porcja)');
      expect(product.caloriesPer100g, 520.0);
      expect(product.proteinPer100g, 38.0);
      expect(product.carbsPer100g, 45.0);
      expect(product.fatPer100g, 18.0);
      expect(product.servingName, 'porcja');
      expect(product.isCustom, isTrue);
    });
  });

  group('RecipeService Tests', () {
    test('getRecipes returns list without crashing when offline or uninitialized', () async {
      final recipes = await RecipeService.instance.getRecipes(category: 'Obiad');
      expect(recipes, isA<List<CommunityRecipe>>());
    });
  });
}
