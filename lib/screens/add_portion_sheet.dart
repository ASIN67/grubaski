import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../utils/app_colors.dart';

/// Configures the amount and destination meal for a new or existing entry.
class AddPortionSheet extends ConsumerStatefulWidget {
  final FoodProduct product;
  final MealType initialMealType;
  final double? initialGrams;
  final DateTime? date;
  final String? entryId;

  const AddPortionSheet({
    super.key,
    required this.product,
    this.initialMealType = MealType.breakfast,
    this.initialGrams,
    this.date,
    this.entryId,
  });

  static Future<MealEntry?> show(
    BuildContext context, {
    required FoodProduct product,
    MealType initialMealType = MealType.breakfast,
    double? initialGrams,
    DateTime? date,
    String? entryId,
  }) {
    return showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddPortionSheet(
        product: product,
        initialMealType: initialMealType,
        initialGrams: initialGrams,
        date: date,
        entryId: entryId,
      ),
    );
  }

  @override
  ConsumerState<AddPortionSheet> createState() => _AddPortionSheetState();
}

class _AddPortionSheetState extends ConsumerState<AddPortionSheet> {
  static final _quantityFormat = NumberFormat('0.###', 'pl_PL');
  static final _quantityPattern = RegExp(r'^\d*(?:[.,]\d*)?$');

  late MealType _selectedMealType;
  late TextEditingController _quantityController;
  late double _maximumQuantity;
  late double? _quantity;
  bool _isSubmitting = false;
  String? _quantityError;

  bool get _isEditing => widget.entryId != null;
  bool get _usesPortions => widget.product.usesPortions;
  double get _unitsPerQuantity => _usesPortions ? 100 : 1;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType;
    final servingSize = widget.product.servingSizeGrams;
    final initialUnits = widget.initialGrams ??
        (servingSize.isFinite && servingSize > 0 ? servingSize : 100.0);
    final initialQuantity = initialUnits / _unitsPerQuantity;
    _quantity = initialQuantity;
    _maximumQuantity = math.max(2000 / _unitsPerQuantity, initialQuantity);
    _quantityController =
        TextEditingController(text: _quantityFormat.format(_quantity));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _setQuantity(double value) {
    setState(() {
      _quantity = value;
      _quantityError = null;
      _quantityController.text = _quantityFormat.format(value);
    });
  }

  void _onQuantityChanged(String text) {
    final quantity = double.tryParse(text.replaceAll(',', '.'));
    setState(() {
      if (quantity != null &&
          quantity.isFinite &&
          quantity > 0 &&
          quantity <= _maximumQuantity) {
        _quantity = quantity;
        _quantityError = null;
      } else {
        _quantity = null;
        _quantityError = 'Podaj ilość większą od zera, maksymalnie '
            '${_quantityFormat.format(_maximumQuantity)}.';
      }
    });
  }

  Future<void> _savePortion() async {
    final quantity = _quantity;
    if (quantity == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final diary = ref.read(diaryProvider.notifier);
      final units = quantity * _unitsPerQuantity;
      final entryId = widget.entryId;
      final entry = entryId == null
          ? await diary.addEntry(
              mealType: _selectedMealType,
              product: widget.product,
              grams: units,
              date: widget.date,
            )
          : await diary.updateEntryPortion(
              id: entryId,
              grams: units,
              mealType: _selectedMealType,
            );

      if (!mounted) return;
      if (entry == null) {
        _showMessage('Tego wpisu nie ma już w dzienniku.');
        return;
      }

      _showMessage(
        _isEditing
            ? 'Zapisano zmiany w dzienniku.'
            : 'Dodano „${widget.product.name}” do dziennika.',
      );
      Navigator.of(context).pop(entry);
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać porcji.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = widget.product.brand?.trim();
    final quantity = _quantity;
    final sliderMin = _usesPortions ? 0.25 : 1.0;
    final sliderMax = _usesPortions ? 5.0 : 500.0;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        Text('Edytuj porcję',
                            style: theme.textTheme.labelLarge),
                      Text(
                        widget.product.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (brand != null && brand.isNotEmpty)
                        Text(
                          brand,
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  tooltip: 'Zamknij',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Posiłek'),
              items: [
                for (final type in MealType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (type) {
                      if (type != null) {
                        setState(() => _selectedMealType = type);
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              enabled: !_isSubmitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) =>
                    _quantityPattern.hasMatch(newValue.text)
                        ? newValue
                        : oldValue),
              ],
              decoration: InputDecoration(
                labelText: _usesPortions ? 'Liczba porcji' : 'Waga porcji',
                suffixText: _usesPortions ? null : 'g',
                errorText: _quantityError,
                errorMaxLines: 2,
              ),
              onChanged: _onQuantityChanged,
            ),
            Slider(
              value: (quantity ?? sliderMin).clamp(sliderMin, sliderMax),
              min: sliderMin,
              max: sliderMax,
              divisions: _usesPortions ? 19 : 499,
              semanticFormatterCallback: (value) =>
                  '${_quantityFormat.format(value)} ${_usesPortions ? "porcji" : "g"}',
              onChanged: _isSubmitting ? null : _setQuantity,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _usesPortions
                  ? [
                      _buildQuickButton(0.5, '½ porcji'),
                      _buildQuickButton(1, '1 porcja'),
                      _buildQuickButton(1.5, '1½ porcji'),
                      _buildQuickButton(2, '2 porcje'),
                    ]
                  : [
                      _buildQuickButton(50, '50 g'),
                      _buildQuickButton(100, '100 g'),
                      _buildQuickButton(150, '150 g'),
                      _buildQuickButton(200, '200 g'),
                      if (widget.product.servingSizeGrams > 0 &&
                          widget.product.servingSizeGrams != 100)
                        _buildQuickButton(
                          widget.product.servingSizeGrams,
                          widget.product.servingName ??
                              '1 porcja (${_quantityFormat.format(widget.product.servingSizeGrams)} g)',
                        ),
                    ],
            ),
            const SizedBox(height: 16),
            _buildNutritionPreview(
                context, (quantity ?? 0) * _unitsPerQuantity),
            if (widget.product.isRecipe)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Składniki przepisu'),
                children: [
                  for (final ingredient in widget.product.recipeIngredients)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ingredient.product.name),
                      trailing: Text(
                        '${_quantityFormat.format(ingredient.grams * (quantity ?? 0))} g',
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _isSubmitting || quantity == null ? null : _savePortion,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
              label: Text(
                _isEditing ? 'Zapisz zmiany' : 'Dodaj do dziennika',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(double quantity, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _quantity != null && (_quantity! - quantity).abs() < 0.001,
      onSelected: _isSubmitting ? null : (_) => _setQuantity(quantity),
    );
  }

  Widget _buildNutritionPreview(BuildContext context, double units) {
    final product = widget.product;
    final theme = Theme.of(context);
    final calories = product.caloriesForGrams(units);
    final fiber = product.fiberForGrams(units);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text('Kalorie w porcji', style: theme.textTheme.titleSmall),
                Text(
                  '${calories.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.caloriesOn(context)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMacroColumn('Białko', product.proteinForGrams(units),
                    AppColors.proteinOn(context)),
                _buildMacroColumn('Węglowodany', product.carbsForGrams(units),
                    AppColors.carbsOn(context)),
                _buildMacroColumn('Tłuszcze', product.fatForGrams(units),
                    AppColors.fatOn(context)),
                if (fiber > 0)
                  _buildMacroColumn(
                      'Błonnik', fiber, AppColors.fiberOn(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroColumn(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${_quantityFormat.format(value)} g',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
