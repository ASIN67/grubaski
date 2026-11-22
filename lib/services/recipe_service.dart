import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// Service managing public and community recipes with Supabase backend
/// and offline-first Hive caching.
class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  static const String _recipesCacheKey = 'cached_community_recipes_json';
  static const String _tableName = 'public_recipes';

  SupabaseClient? get _supabaseClient {
    if (!SupabaseService.instance.isInitialized) return null;
    return SupabaseService.instance.client;
  }

  /// Fetches recipes from Supabase with optional [category] filter and [searchQuery].
  /// Falls back to offline Hive cache if network is unavailable.
  Future<List<CommunityRecipe>> getRecipes({
    String? category,
    String? searchQuery,
  }) async {
    List<CommunityRecipe> allRecipes = [];

    final client = _supabaseClient;
    if (client != null) {
      try {
        var query = client.from(_tableName).select();

        final res = await query.order('created_at', ascending: false);
        allRecipes = res
            .map((map) => CommunityRecipe.fromMap(map))
            .toList();

        // Update local cache
        await _cacheRecipesLocally(allRecipes);
      } catch (e) {
        debugPrint('RecipeService: Network fetch failed ($e). Loading local cache.');
        allRecipes = _loadRecipesFromCache();
      }
    } else {
      allRecipes = _loadRecipesFromCache();
    }

    // Apply in-memory filtering
    return allRecipes.where((r) {
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'wszystkie') {
        if (r.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchTitle = r.title.toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        final matchIng = r.ingredients
            .any((ing) => ing.name.toLowerCase().contains(q));
        if (!matchTitle && !matchDesc && !matchIng) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Publishes a new recipe to Supabase and immediately saves to local cache.
  Future<CommunityRecipe> createRecipe({
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
    String? authorId,
  }) async {
    final client = _supabaseClient;
    final now = DateTime.now();

    final payload = {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'prep_time_minutes': prepTimeMinutes,
      'servings': servings,
      'calories_per_serving': caloriesPerServing,
      'protein_per_serving': proteinPerServing,
      'carbs_per_serving': carbsPerServing,
      'fat_per_serving': fatPerServing,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'steps': steps.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'author_name': authorName.trim(),
      'author_id': authorId ?? client?.auth.currentUser?.id,
      'is_verified': false,
    };

    CommunityRecipe createdRecipe;

    if (client != null) {
      try {
        final inserted = await client
            .from(_tableName)
            .insert(payload)
            .select()
            .single();

        createdRecipe = CommunityRecipe.fromMap(
          Map<String, dynamic>.from(inserted),
        );
      } catch (e) {
        debugPrint('RecipeService: Cloud publish failed ($e). Storing locally.');
        createdRecipe = CommunityRecipe(
          id: 'local_${now.millisecondsSinceEpoch}',
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
          authorId: authorId,
          createdAt: now,
        );
      }
    } else {
      createdRecipe = CommunityRecipe(
        id: 'local_${now.millisecondsSinceEpoch}',
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
        authorId: authorId,
        createdAt: now,
      );
    }

    // Prepend to local cache
    final currentList = _loadRecipesFromCache();
    currentList.insert(0, createdRecipe);
    await _cacheRecipesLocally(currentList);

    return createdRecipe;
  }

  Future<void> _cacheRecipesLocally(List<CommunityRecipe> recipes) async {
    try {
      final jsonList = recipes.map((r) => r.toMap()).toList();
      final encoded = jsonEncode(jsonList);
      await HiveService.instance.settingsBox.put(_recipesCacheKey, encoded);
    } catch (e) {
      debugPrint('RecipeService: Cache write failed ($e)');
    }
  }

  List<CommunityRecipe> _loadRecipesFromCache() {
    try {
      final raw = HiveService.instance.settingsBox.get(_recipesCacheKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((m) => CommunityRecipe.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('RecipeService: Cache read failed ($e)');
    }
    return [];
  }
}
