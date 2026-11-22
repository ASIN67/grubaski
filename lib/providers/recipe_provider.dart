import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/recipe_service.dart';
import 'diary_provider.dart';

class RecipeState {
  final bool isLoading;
  final List<CommunityRecipe> recipes;
  final String selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  const RecipeState({
    this.isLoading = false,
    this.recipes = const [],
    this.selectedCategory = 'Wszystkie',
    this.searchQuery = '',
    this.errorMessage,
  });

  RecipeState copyWith({
    bool? isLoading,
    List<CommunityRecipe>? recipes,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecipeState(
      isLoading: isLoading ?? this.isLoading,
      recipes: recipes ?? this.recipes,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  final RecipeService _recipeService;
  final Ref _ref;

  RecipeNotifier(this._recipeService, this._ref) : super(const RecipeState()) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _recipeService.getRecipes(
        category: state.selectedCategory,
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(
        isLoading: false,
        recipes: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Nie udało się pobrać przepisów: $e',
      );
    }
  }

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    loadRecipes();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadRecipes();
  }

  Future<CommunityRecipe> publishRecipe({
    required String title,
    required String description,
    required String category,
    required int prepTimeMinutes,
    int servings = 1,
    required int caloriesPerServing,
    required double proteinPerServing,
    required double carbsPerServing,
    required double fatPerServing,
    required List<RecipeIngredientItem> ingredients,
    required List<String> steps,
    String authorName = 'Użytkownik Grubaska',
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _recipeService.createRecipe(
        title: title,
        description: description,
        category: category,
        prepTimeMinutes: prepTimeMinutes,
        servings: servings,
        caloriesPerServing: caloriesPerServing,
        proteinPerServing: proteinPerServing,
        carbsPerServing: carbsPerServing,
        fatPerServing: fatPerServing,
        ingredients: ingredients,
        steps: steps,
        authorName: authorName,
      );

      final updatedList = [created, ...state.recipes];
      state = state.copyWith(
        isLoading: false,
        recipes: updatedList,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Błąd podczas publikacji przepisu: $e',
      );
      rethrow;
    }
  }

  Future<MealEntry> addRecipeToDiary({
    required CommunityRecipe recipe,
    required MealType mealType,
    int servings = 1,
    DateTime? date,
  }) async {
    final product = recipe.toFoodProduct();
    final totalGrams = 100.0 * servings;
    return await _ref.read(diaryProvider.notifier).addEntry(
          mealType: mealType,
          product: product,
          grams: totalGrams,
          date: date,
        );
  }
}

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService.instance;
});

final recipeProvider =
    StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  final service = ref.watch(recipeServiceProvider);
  return RecipeNotifier(service, ref);
});
