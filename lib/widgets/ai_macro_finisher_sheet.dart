import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_meal_models.dart';
import '../models/meal_type.dart';
import '../providers/ai_meal_provider.dart';
import '../providers/diary_provider.dart';
import '../utils/app_colors.dart';

class AiMacroFinisherSheet extends ConsumerStatefulWidget {
  final int remainingCalories;
  final double remainingProtein;
  final double remainingCarbs;
  final double remainingFat;

  const AiMacroFinisherSheet({
    super.key,
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFat,
  });

  static Future<void> show(
    BuildContext context, {
    required int remainingCalories,
    required double remainingProtein,
    required double remainingCarbs,
    required double remainingFat,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiMacroFinisherSheet(
        remainingCalories: remainingCalories,
        remainingProtein: remainingProtein,
        remainingCarbs: remainingCarbs,
        remainingFat: remainingFat,
      ),
    );
  }

  @override
  ConsumerState<AiMacroFinisherSheet> createState() => _AiMacroFinisherSheetState();
}

class _AiMacroFinisherSheetState extends ConsumerState<AiMacroFinisherSheet> {
  final _prefController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<AiMealSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _prefController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(aiMealServiceProvider);
      final results = await service.suggestMealsForRemainingMacro(
        remainingCalories: widget.remainingCalories > 50 ? widget.remainingCalories : 250,
        remainingProtein: widget.remainingProtein > 5 ? widget.remainingProtein : 20.0,
        remainingCarbs: widget.remainingCarbs > 5 ? widget.remainingCarbs : 25.0,
        remainingFat: widget.remainingFat > 2 ? widget.remainingFat : 8.0,
        dietaryPreferences: _prefController.text.trim().isNotEmpty
            ? _prefController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSuggestionToDiary(AiMealSuggestion suggestion, MealType meal) async {
    try {
      final product = suggestion.toFoodProduct();
      await ref.read(diaryProvider.notifier).addEntry(
            mealType: meal,
            product: product,
            grams: 100.0,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreenDark,
            content: Text('Dodano „${suggestion.title}” do: ${meal.displayName}!'),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Top drag handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryGreenDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dokończ moje makro (AI)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Pozostało: ${widget.remainingCalories} kcal • B: ${widget.remainingProtein.toStringAsFixed(1)}g, W: ${widget.remainingCarbs.toStringAsFixed(1)}g, T: ${widget.remainingFat.toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter/preferences input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _prefController,
                        decoration: InputDecoration(
                          hintText: 'Np. na słodko, szybkie, z twarogiem...',
                          prefixIcon: const Icon(Icons.tune_rounded, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _fetchSuggestions(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _isLoading ? null : _fetchSuggestions,
                      child: const Text('Szukaj'),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primaryGreen),
                            const SizedBox(height: 16),
                            Text(
                              'Gemini dobiera idealne posiłki pod Twoje makro...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _fetchSuggestions,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Spróbuj ponownie'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _suggestions.length,
                            itemBuilder: (ctx, idx) {
                              final item = _suggestions[idx];
                              return _SuggestionCard(
                                suggestion: item,
                                onAdd: (meal) => _addSuggestionToDiary(item, meal),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final AiMealSuggestion suggestion;
  final void Function(MealType meal) onAdd;

  const _SuggestionCard({
    required this.suggestion,
    required this.onAdd,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  MealType _selectedMeal = MealType.dinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = widget.suggestion;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      '${s.prepTimeMinutes} min',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            if (s.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                s.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Macros pill row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMacroPill('${s.calories} kcal', AppColors.primaryGreen),
                _buildMacroPill('B: ${s.protein.toStringAsFixed(1)}g', AppColors.proteinBlue),
                _buildMacroPill('W: ${s.carbs.toStringAsFixed(1)}g', AppColors.carbsAmber),
                _buildMacroPill('T: ${s.fat.toStringAsFixed(1)}g', AppColors.fatRose),
              ],
            ),

            if (s.ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Składniki: ${s.ingredients.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MealType>(
                    value: _selectedMeal,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: MealType.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.displayName, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMeal = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Dodaj do dziennika', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => widget.onAdd(_selectedMeal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
