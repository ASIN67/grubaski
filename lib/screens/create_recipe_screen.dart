import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/food_product.dart';
import '../providers/product_search_provider.dart';
import '../utils/app_colors.dart';
import 'create_custom_product_screen.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredients = <RecipeIngredient>[];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final product = await Navigator.of(context).push<FoodProduct>(
      MaterialPageRoute(builder: (_) => const _IngredientPickerScreen()),
    );
    if (mounted && product != null) await _setIngredient(product);
  }

  Future<void> _setIngredient(FoodProduct product, {int? index}) async {
    final ingredient = await showDialog<RecipeIngredient>(
      context: context,
      builder: (_) => _IngredientAmountDialog(
        product: product,
        initialGrams: index == null ? null : _ingredients[index].grams,
      ),
    );
    if (!mounted || ingredient == null) return;
    setState(() {
      if (index == null) {
        _ingredients.add(ingredient);
      } else {
        _ingredients[index] = ingredient;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      setState(() => _error = 'Dodaj co najmniej jeden składnik.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final recipe = await ref.read(productRepositoryProvider).createRecipe(
            name: _nameController.text,
            ingredients: _ingredients,
          );
      if (mounted) Navigator.of(context).pop(recipe);
    } catch (error) {
      debugPrint('Recipe save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Nie udało się zapisać przepisu. Spróbuj ponownie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat('0.##', 'pl_PL');
    final totals = RecipeIngredient.totalNutrition(_ingredients);
    final metrics = [
      ('${format.format(totals.calories)} kcal', AppColors.caloriesOn(context)),
      (
        'Białko ${format.format(totals.protein)} g',
        AppColors.proteinOn(context)
      ),
      (
        'Węglowodany ${format.format(totals.carbs)} g',
        AppColors.carbsOn(context)
      ),
      ('Tłuszcze ${format.format(totals.fat)} g', AppColors.fatOn(context)),
      ('Błonnik ${format.format(totals.fiber)} g', AppColors.fiberOn(context)),
    ];

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Nowy przepis')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa potrawy',
                    hintText: 'np. Moja owsianka',
                  ),
                  validator: (text) => (text ?? '').trim().isEmpty
                      ? 'Wpisz nazwę potrawy.'
                      : null,
                ),
                const SizedBox(height: 20),
                Text('Składniki', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final (index, ingredient) in _ingredients.indexed)
                  Card(
                    child: ListTile(
                      title: Text(ingredient.product.fullDisplayName),
                      subtitle: Text(
                        '${format.format(ingredient.grams)} g · '
                        '${format.format(ingredient.product.caloriesForGrams(ingredient.grams))} kcal',
                      ),
                      onTap: _saving
                          ? null
                          : () =>
                              _setIngredient(ingredient.product, index: index),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        tooltip: 'Usuń składnik',
                        onPressed: _saving
                            ? null
                            : () =>
                                setState(() => _ingredients.removeAt(index)),
                      ),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _addIngredient,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Dodaj składnik'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wartości w 1 porcji',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            for (final (label, color) in metrics)
                              Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Zapisywanie…' : 'Zapisz przepis'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientPickerScreen extends ConsumerStatefulWidget {
  const _IngredientPickerScreen();

  @override
  ConsumerState<_IngredientPickerScreen> createState() =>
      _IngredientPickerScreenState();
}

class _IngredientPickerScreenState
    extends ConsumerState<_IngredientPickerScreen> {
  final _searchScope = Object();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    final product = await Navigator.of(context).push<FoodProduct>(
      MaterialPageRoute(builder: (_) => const CreateCustomProductScreen()),
    );
    if (mounted && product != null) Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final provider = productSearchProvider(_searchScope);
    final search = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final products =
        search.results.where((product) => !product.usesPortions).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Wybierz składnik')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Szukaj składnika',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: notifier.onQueryChanged,
                      onSubmitted: notifier.searchImmediate,
                    ),
                    const SizedBox(height: 8),
                    if (search.isLoading) const LinearProgressIndicator(),
                    if (search.errorMessage != null) Text(search.errorMessage!),
                    TextButton.icon(
                      onPressed: _createProduct,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Utwórz własny produkt'),
                    ),
                    if (products.isEmpty && !search.isLoading)
                      const Text('Wyszukaj produkt lub utwórz własny.'),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: ListTile(
                      title: Text(product.fullDisplayName),
                      trailing: const Icon(Icons.add_rounded),
                      onTap: () => Navigator.of(context).pop(product),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _IngredientUnit { grams, serving, milliliters }

class _IngredientAmountDialog extends StatefulWidget {
  final FoodProduct product;
  final double? initialGrams;

  const _IngredientAmountDialog({required this.product, this.initialGrams});

  @override
  State<_IngredientAmountDialog> createState() =>
      _IngredientAmountDialogState();
}

class _IngredientAmountDialogState extends State<_IngredientAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _format = NumberFormat('0.########', 'pl_PL');
  late final TextEditingController _amount;
  final _gramsPer100Ml = TextEditingController();
  _IngredientUnit _unit = _IngredientUnit.grams;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: _format
          .format(widget.initialGrams ?? widget.product.servingSizeGrams),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _gramsPer100Ml.dispose();
    super.dispose();
  }

  double? _parse(String? text) {
    final value = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parse(_amount.text)!;
    final grams = switch (_unit) {
      _IngredientUnit.grams => amount,
      _IngredientUnit.serving => amount * widget.product.servingSizeGrams,
      _IngredientUnit.milliliters =>
        amount / 100 * _parse(_gramsPer100Ml.text)!,
    };
    if (!grams.isFinite || grams <= 0) {
      setState(() => _amountError = 'Podaj mniejszą, dodatnią ilość.');
      return;
    }
    Navigator.of(context)
        .pop(RecipeIngredient(product: widget.product, grams: grams));
  }

  @override
  Widget build(BuildContext context) {
    const keyboard = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: Text(widget.product.name),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<_IngredientUnit>(
              decoration: const InputDecoration(labelText: 'Jednostka'),
              isExpanded: true,
              value: _unit,
              items: [
                const DropdownMenuItem(
                  value: _IngredientUnit.grams,
                  child: Text('Gramy'),
                ),
                if (widget.product.servingSizeGrams.isFinite &&
                    widget.product.servingSizeGrams > 0)
                  DropdownMenuItem(
                    value: _IngredientUnit.serving,
                    child: Text(
                      'Porcje (1 = ${_format.format(widget.product.servingSizeGrams)} g)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const DropdownMenuItem(
                  value: _IngredientUnit.milliliters,
                  child: Text('Mililitry'),
                ),
              ],
              onChanged: (unit) => setState(() {
                if (unit == null || unit == _unit) return;
                _unit = unit;
                _amountError = null;
                _amount.text = switch (unit) {
                  _IngredientUnit.grams => _format.format(
                      widget.initialGrams ?? widget.product.servingSizeGrams),
                  _IngredientUnit.serving => '1',
                  _IngredientUnit.milliliters => '100',
                };
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: keyboard,
              decoration:
                  InputDecoration(labelText: 'Ilość', errorText: _amountError),
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
              validator: (text) =>
                  _parse(text) == null ? 'Wpisz liczbę większą od 0.' : null,
            ),
            if (_unit == _IngredientUnit.milliliters) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _gramsPer100Ml,
                keyboardType: keyboard,
                decoration: const InputDecoration(
                  labelText: 'Masa 100 ml',
                  suffixText: 'g',
                ),
                validator: (text) =>
                    _parse(text) == null ? 'Podaj, ile waży 100 ml.' : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Zatwierdź')),
      ],
    );
  }
}
