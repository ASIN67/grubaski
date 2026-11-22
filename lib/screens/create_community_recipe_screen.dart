import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_colors.dart';

class CreateCommunityRecipeScreen extends ConsumerStatefulWidget {
  const CreateCommunityRecipeScreen({super.key});

  @override
  ConsumerState<CreateCommunityRecipeScreen> createState() =>
      _CreateCommunityRecipeScreenState();
}

class _CreateCommunityRecipeScreenState
    extends ConsumerState<CreateCommunityRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _authorController = TextEditingController(text: 'Ja (Użytkownik)');
  final _prepTimeController = TextEditingController(text: '20');
  final _servingsController = TextEditingController(text: '1');
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedCategory = 'Obiad';
  final List<String> _categories = [
    'Śniadanie',
    'Obiad',
    'Kolacja',
    'Przekąska',
  ];

  // Dynamic ingredients list
  final List<Map<String, TextEditingController>> _ingredientControllers = [];

  // Dynamic step-by-step controllers
  final List<TextEditingController> _stepControllers = [];

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Default initial 2 ingredients
    _addIngredientField('Np. Pierś z kurczaka', '150g');
    _addIngredientField('Np. Ryż basmati', '50g');

    // Default initial 2 steps
    _addStepField('Ugotuj ryż i przygotuj mięso.');
    _addStepField('Podsmaż kurczaka na patelni z przyprawami.');
  }

  void _addIngredientField([String name = '', String amount = '']) {
    setState(() {
      _ingredientControllers.add({
        'name': TextEditingController(text: name),
        'amount': TextEditingController(text: amount),
      });
    });
  }

  void _removeIngredientField(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        final removed = _ingredientControllers.removeAt(index);
        removed['name']?.dispose();
        removed['amount']?.dispose();
      });
    }
  }

  void _addStepField([String text = '']) {
    setState(() {
      _stepControllers.add(TextEditingController(text: text));
    });
  }

  void _removeStepField(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        final removed = _stepControllers.removeAt(index);
        removed.dispose();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _authorController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();

    for (final pair in _ingredientControllers) {
      pair['name']?.dispose();
      pair['amount']?.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ingredients = <RecipeIngredientItem>[];
    for (final c in _ingredientControllers) {
      final name = c['name']?.text.trim() ?? '';
      final amount = c['amount']?.text.trim() ?? '';
      if (name.isNotEmpty) {
        ingredients.add(
          RecipeIngredientItem(
            name: name,
            amount: amount.isNotEmpty ? amount : 'wg uznania',
          ),
        );
      }
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodaj przynajmniej 1 składnik!')),
      );
      return;
    }

    final steps = <String>[];
    for (final c in _stepControllers) {
      final text = c.text.trim();
      if (text.isNotEmpty) {
        steps.add(text);
      }
    }

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodaj przynajmniej 1 krok przygotowania!')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final kcal = int.tryParse(_kcalController.text.trim()) ?? 350;
      final protein = double.tryParse(_proteinController.text.trim().replaceAll(',', '.')) ?? 25.0;
      final carbs = double.tryParse(_carbsController.text.trim().replaceAll(',', '.')) ?? 35.0;
      final fat = double.tryParse(_fatController.text.trim().replaceAll(',', '.')) ?? 10.0;
      final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 20;
      final servings = int.tryParse(_servingsController.text.trim()) ?? 1;

      final created = await ref.read(recipeProvider.notifier).publishRecipe(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            category: _selectedCategory,
            prepTimeMinutes: prepTime,
            servings: servings,
            caloriesPerServing: kcal,
            proteinPerServing: protein,
            carbsPerServing: carbs,
            fatPerServing: fat,
            ingredients: ingredients,
            steps: steps,
            authorName: _authorController.text.trim().isNotEmpty
                ? _authorController.text.trim()
                : 'Użytkownik Grubaska',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreenDark,
            content: Text('Opublikowano przepis „${created.title}”! Jest już widoczny dla wszystkich.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Nie udało się opublikować przepisu: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj własny przepis', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _isPublishing ? null : _submitRecipe,
            icon: _isPublishing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: const Text('Opublikuj', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded, color: AppColors.primaryGreenDark, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Twój przepis zobaczą inni użytkownicy!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Podziel się swoim fit pomysłem ze składnikami i krokami.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Basic details
            Text('Podstawowe informacje', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Nazwa przepisu *',
                hintText: 'np. Fit Zapiekanka Makaronowa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Podaj nazwę przepisu' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Krótki opis',
                hintText: 'np. Szybki, wysokobiałkowy obiad do zrobienia w 20 minut.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategoria',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Czas (min)',
                      suffixText: 'min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Podaj czas' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Liczba porcji',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      labelText: 'Twój podpis / autor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Macros section
            Text('Wartości odżywcze na 1 porcję', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kcalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kalorie (kcal) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Białko (g) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Węgle (g) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tłuszcz (g) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Ingredients list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Składniki (${_ingredientControllers.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _addIngredientField(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Dodaj składnik'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._ingredientControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final controllers = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: controllers['name'],
                        decoration: InputDecoration(
                          hintText: 'Nazwa składnika (np. Jajka)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: controllers['amount'],
                        decoration: InputDecoration(
                          hintText: 'Ilość (np. 2 sztuki)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                      onPressed: () => _removeIngredientField(idx),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 28),

            // Step by step preparation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Krok po kroku (${_stepControllers.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _addStepField(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Dodaj krok'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._stepControllers.asMap().entries.map((entry) {
              final stepIndex = entry.key + 1;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$stepIndex',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Krok $stepIndex: opisz co zrobić...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                      onPressed: () => _removeStepField(entry.key),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _addStepField(),
              icon: const Icon(Icons.add_rounded),
              label: Text('Dodaj kolejny krok (Krok ${_stepControllers.length + 1})'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isPublishing ? null : _submitRecipe,
              icon: _isPublishing
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isPublishing ? 'Publikowanie...' : 'Opublikuj przepis w społeczności',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
