import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../utils/date_formatter.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final MealType? initialMealType;
  final MealEntry? existingEntry;

  const QuickAddSheet._({
    required this.date,
    this.initialMealType,
    this.existingEntry,
  });

  static Future<MealEntry?> show(
    BuildContext context, {
    required DateTime date,
    MealType? initialMealType,
    MealEntry? existingEntry,
  }) {
    return showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuickAddSheet._(
        date: date,
        initialMealType: initialMealType,
        existingEntry: existingEntry,
      ),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late MealType _mealType;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    final format = NumberFormat('0.########', 'pl_PL');
    _name = TextEditingController(text: entry?.product.name);
    _calories = TextEditingController(
      text: entry == null ? null : format.format(entry.calories),
    );
    _protein = TextEditingController(
      text: entry == null ? null : format.format(entry.protein),
    );
    _carbs = TextEditingController(
      text: entry == null ? null : format.format(entry.carbs),
    );
    _fat = TextEditingController(
      text: entry == null ? null : format.format(entry.fat),
    );
    _mealType = entry?.mealType ?? widget.initialMealType ?? MealType.breakfast;
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? _parseAmount(String text) {
    final amount = double.tryParse(text.trim().replaceAll(',', '.'));
    return amount != null && amount.isFinite && amount >= 0 ? amount : null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final existing = widget.existingEntry;
    final name = _name.text.trim();
    final product = FoodProduct(
      id: existing?.product.id ?? const Uuid().v4(),
      name: name.isEmpty ? 'Szybki wpis' : name,
      caloriesPer100g: _parseAmount(_calories.text)!,
      proteinPer100g: _parseAmount(_protein.text) ?? 0,
      carbsPer100g: _parseAmount(_carbs.text) ?? 0,
      fatPer100g: _parseAmount(_fat.text) ?? 0,
      isQuickAdd: true,
    );

    try {
      final diary = ref.read(diaryProvider.notifier);
      final entry = existing == null
          ? await diary.addEntry(
              mealType: _mealType,
              product: product,
              grams: 100,
              date: widget.date,
            )
          : await diary.updateQuickEntry(
              id: existing.id,
              product: product,
              mealType: _mealType,
            );
      if (!mounted) return;
      if (entry == null) {
        setState(() {
          _saving = false;
          _saveError = 'Tego wpisu nie ma już w Dzienniku.';
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zapisano w Dzienniku · ${entry.mealType.displayName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(entry);
    } catch (error) {
      debugPrint('Quick entry save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Nie udało się zapisać wpisu. Spróbuj ponownie.';
      });
    }
  }

  Widget _amountField(
    TextEditingController controller,
    String label,
    String unit, {
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, suffixText: unit),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return isRequired ? 'Wpisz liczbę kalorii.' : null;
        return _parseAmount(text) == null ? 'Wpisz liczbę od 0.' : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existingEntry == null
                      ? 'Szybki wpis'
                      : 'Edytuj szybki wpis',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(DateFormatter.formatPolishDisplayDate(widget.date)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa',
                    hintText: 'np. Lunch na mieście',
                  ),
                ),
                const SizedBox(height: 12),
                _amountField(_calories, 'Kalorie', 'kcal', isRequired: true),
                const SizedBox(height: 16),
                Text('Makroskładniki (opcjonalnie)',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _amountField(_protein, 'Białko', 'g'),
                const SizedBox(height: 8),
                _amountField(_carbs, 'Węglowodany', 'g'),
                const SizedBox(height: 8),
                _amountField(_fat, 'Tłuszcze', 'g'),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  value: _mealType,
                  decoration: const InputDecoration(labelText: 'Posiłek'),
                  items: [
                    for (final meal in MealType.values)
                      DropdownMenuItem(
                          value: meal, child: Text(meal.displayName)),
                  ],
                  onChanged: _saving
                      ? null
                      : (meal) => setState(() => _mealType = meal!),
                ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _saveError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Zapisywanie…' : 'Zapisz wpis'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
