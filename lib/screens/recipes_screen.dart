import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_type.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_colors.dart';
import 'create_community_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Wszystkie',
    'Śniadanie',
    'Obiad',
    'Kolacja',
    'Przekąska',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _quickAddRecipeToDiary(CommunityRecipe recipe) {
    MealType selectedMeal = MealType.breakfast;
    final catLower = recipe.category.toLowerCase();
    if (catLower.contains('obiad')) {
      selectedMeal = MealType.lunch;
    } else if (catLower.contains('kolacj')) {
      selectedMeal = MealType.dinner;
    } else if (catLower.contains('przekąsk') || catLower.contains('deser')) {
      selectedMeal = MealType.snacks;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        MealType meal = selectedMeal;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Dodaj porcję do Dziennika'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipe.title}\n(${recipe.caloriesPerServing} kcal • B: ${recipe.proteinPerServing}g, W: ${recipe.carbsPerServing}g, T: ${recipe.fatPerServing}g)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text('Do którego posiłku?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MealType>(
                    value: meal,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: MealType.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.displayName));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => meal = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(recipeProvider.notifier).addRecipeToDiary(
                          recipe: recipe,
                          mealType: meal,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primaryGreenDark,
                          content: Text('Dodano „${recipe.title}” do: ${meal.displayName}!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipeState = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Książka Przepisów',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Odśwież przepisy',
            onPressed: () => ref.read(recipeProvider.notifier).loadRecipes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Dodaj przepis', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push<CommunityRecipe>(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityRecipeScreen()),
          );
          if (created != null && mounted) {
            ref.read(recipeProvider.notifier).loadRecipes();
          }
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj przepisów, składników...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(recipeProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(recipeProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Categories Filter Bar
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final cat = _categories[index];
                final isSelected = recipeState.selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryGreenDark : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (_) {
                    ref.read(recipeProvider.notifier).setCategory(cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Recipe List
          Expanded(
            child: recipeState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : recipeState.recipes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Brak przepisów w tej kategorii',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Bądź pierwszą osobą, która doda swój fit przepis dla społeczności!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(recipeProvider.notifier).loadRecipes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: recipeState.recipes.length,
                          itemBuilder: (ctx, index) {
                            final recipe = recipeState.recipes[index];
                            return _RecipeCard(
                              recipe: recipe,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              },
                              onQuickAdd: () => _quickAddRecipeToDiary(recipe),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final CommunityRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tag & time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.category,
                      style: const TextStyle(
                        color: AppColors.primaryGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${recipe.prepTimeMinutes} min',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      recipe.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                recipe.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Bottom row: Macros and Quick Add Button
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildMacroBadge('${recipe.caloriesPerServing} kcal', AppColors.primaryGreen),
                        _buildMacroBadge('B: ${recipe.proteinPerServing}g', AppColors.proteinBlue),
                        _buildMacroBadge('W: ${recipe.carbsPerServing}g', AppColors.carbsAmber),
                        _buildMacroBadge('T: ${recipe.fatPerServing}g', AppColors.fatRose),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                      foregroundColor: AppColors.primaryGreenDark,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    tooltip: 'Dodaj porcję do posiłku',
                    onPressed: onQuickAdd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
