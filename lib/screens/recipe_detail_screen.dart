import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_type.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_colors.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final CommunityRecipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int _servingsCount = 1;
  final Set<int> _checkedIngredients = {};

  void _showAddToDiaryModal() {
    MealType selectedMeal = MealType.breakfast;
    final categoryLower = widget.recipe.category.toLowerCase();
    if (categoryLower.contains('obiad')) {
      selectedMeal = MealType.lunch;
    } else if (categoryLower.contains('kolacj')) {
      selectedMeal = MealType.dinner;
    } else if (categoryLower.contains('przekąsk') || categoryLower.contains('deser')) {
      selectedMeal = MealType.snacks;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        MealType currentMeal = selectedMeal;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final totalKcal = widget.recipe.caloriesPerServing * _servingsCount;
            final totalP = (widget.recipe.proteinPerServing * _servingsCount).toStringAsFixed(1);
            final totalC = (widget.recipe.carbsPerServing * _servingsCount).toStringAsFixed(1);
            final totalF = (widget.recipe.fatPerServing * _servingsCount).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Dodaj przepis do Dziennika',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.recipe.title} • $_servingsCount porcja ($totalKcal kcal, B: ${totalP}g, W: ${totalC}g, T: ${totalF}g)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Wybierz posiłek:',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MealType.values.map((meal) {
                      final isSelected = currentMeal == meal;
                      return ChoiceChip(
                        label: Text(meal.displayName),
                        selected: isSelected,
                        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryGreenDark : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => currentMeal = meal);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Zatwierdź i dodaj do posiłku',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ref.read(recipeProvider.notifier).addRecipeToDiary(
                              recipe: widget.recipe,
                              mealType: currentMeal,
                              servings: _servingsCount,
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primaryGreenDark,
                              content: Text(
                                'Dodano „${widget.recipe.title}” ($_servingsCount porcji) do: ${currentMeal.displayName}!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Błąd dodawania do dziennika: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
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
    final r = widget.recipe;

    final multiplier = _servingsCount;
    final kcal = r.caloriesPerServing * multiplier;
    final protein = (r.proteinPerServing * multiplier).toStringAsFixed(1);
    final carbs = (r.carbsPerServing * multiplier).toStringAsFixed(1);
    final fat = (r.fatPerServing * multiplier).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Dodaj do Dziennika',
            onPressed: _showAddToDiaryModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category & Author Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.category,
                    style: const TextStyle(
                      color: AppColors.primaryGreenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${r.prepTimeMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Autor: ${r.authorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title and Description
            Text(
              r.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                r.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Servings selector & Macro Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wartości dla porcji:',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                visualDensity: VisualDensity.compact,
                                onPressed: _servingsCount > 1
                                    ? () => setState(() => _servingsCount--)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$_servingsCount',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                visualDensity: VisualDensity.compact,
                                onPressed: _servingsCount < 10
                                    ? () => setState(() => _servingsCount++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroPill('Kalorie', '$kcal kcal', AppColors.primaryGreen, theme),
                        _buildMacroPill('Białko', '${protein}g', AppColors.proteinBlue, theme),
                        _buildMacroPill('Węgle', '${carbs}g', AppColors.carbsAmber, theme),
                        _buildMacroPill('Tłuszcze', '${fat}g', AppColors.fatRose, theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ingredients
            Text(
              'Składniki (${r.ingredients.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: r.ingredients.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
                itemBuilder: (ctx, idx) {
                  final ing = r.ingredients[idx];
                  final isChecked = _checkedIngredients.contains(idx);
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.primaryGreen,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(
                      ing.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    subtitle: Text(
                      'Ilość: ${ing.amount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedIngredients.add(idx);
                        } else {
                          _checkedIngredients.remove(idx);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Step by step preparation instructions
            Text(
              'Sposób przygotowania (Krok po kroku)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...r.steps.asMap().entries.map((entry) {
              final stepIndex = entry.key + 1;
              final stepText = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$stepIndex',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          stepText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Big Action Button at bottom
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(
                'Dodaj ten posiłek do Dziennika ($kcal kcal)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _showAddToDiaryModal,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
