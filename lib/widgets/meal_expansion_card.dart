import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/meal_entry.dart';
import '../models/meal_type.dart';
import '../utils/app_colors.dart';

enum MealCardAction { copyFromYesterday, copyToMeal, quickAdd, aiEstimate }

/// A collapsible card with meal totals, entry actions, and product shortcuts.
class MealExpansionCard extends StatefulWidget {
  final MealType mealType;
  final List<MealEntry> entries;
  final VoidCallback onAddProduct;
  final void Function(MealEntry entry) onDeleteEntry;
  final void Function(MealEntry entry)? onTapEntry;
  final void Function(MealEntry entry)? onUndoDelete;
  final ValueChanged<MealCardAction>? onAction;
  final bool canCopyFromYesterday;
  final bool? isInitiallyExpanded;

  MealExpansionCard({
    super.key,
    required this.mealType,
    required this.entries,
    VoidCallback? onAddProduct,
    VoidCallback? onAddProductPressed,
    void Function(MealEntry entry)? onDeleteEntry,
    void Function(MealEntry entry)? onDelete,
    this.onTapEntry,
    this.onUndoDelete,
    this.onAction,
    this.canCopyFromYesterday = true,
    this.isInitiallyExpanded,
  })  : onAddProduct = onAddProduct ?? onAddProductPressed ?? (() {}),
        onDeleteEntry = onDeleteEntry ?? onDelete ?? ((_) {});

  @override
  State<MealExpansionCard> createState() => _MealExpansionCardState();
}

class _MealExpansionCardState extends State<MealExpansionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded ?? widget.entries.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant MealExpansionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.isEmpty && widget.entries.isNotEmpty) {
      _isExpanded = true;
    }
  }

  void _handleDismiss(BuildContext context, MealEntry entry) {
    widget.onDeleteEntry(entry);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usunięto „${entry.product.name}”'),
        behavior: SnackBarBehavior.floating,
        action: widget.onUndoDelete != null
            ? SnackBarAction(
                label: 'Cofnij',
                onPressed: () => widget.onUndoDelete!(entry),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealColor = switch (widget.mealType) {
      MealType.breakfast => AppColors.carbsOn(context),
      MealType.secondBreakfast => AppColors.caloriesOn(context),
      MealType.lunch => AppColors.fiberOn(context),
      MealType.snacks => AppColors.fatOn(context),
      MealType.dinner => theme.colorScheme.primary,
    };

    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final entry in widget.entries) {
      calories += entry.calories;
      protein += entry.protein;
      carbs += entry.carbs;
      fat += entry.fat;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border(context)),
      ),
      color: AppColors.cardBackground(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: mealColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox.square(
                          dimension: 40,
                          child: Icon(widget.mealType.icon,
                              color: mealColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.mealType.displayName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: theme.colorScheme.primary,
                        tooltip: 'Dodaj do ${widget.mealType.displayName}',
                        onPressed: widget.onAddProduct,
                      ),
                      if (widget.onAction != null) _buildActionMenu(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary(context),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${calories.round()} kcal',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.caloriesOn(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _MacroPill(
                          label: 'B',
                          grams: protein,
                          color: AppColors.proteinOn(context)),
                      _MacroPill(
                          label: 'W',
                          grams: carbs,
                          color: AppColors.carbsOn(context)),
                      _MacroPill(
                          label: 'T',
                          grams: fat,
                          color: AppColors.fatOn(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child:
                _isExpanded ? _buildEntries(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<MealCardAction>(
      tooltip: 'Opcje posiłku „${widget.mealType.displayName}”',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: widget.onAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MealCardAction.aiEstimate,
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFEC4899)),
              SizedBox(width: 8),
              Text('✨ Oszacuj przez AI'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MealCardAction.quickAdd,
          child: Text('+ Szybki wpis'),
        ),
        PopupMenuItem(
          value: MealCardAction.copyFromYesterday,
          enabled: widget.canCopyFromYesterday,
          child: const Text('Skopiuj z wczoraj'),
        ),
        PopupMenuItem(
          value: MealCardAction.copyToMeal,
          enabled: widget.entries.isNotEmpty,
          child: const Text('Skopiuj do innego dnia/posiłku'),
        ),
      ],
    );
  }

  Widget _buildEntries(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: AppColors.border(context)),
        if (widget.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            child: Text(
              'Brak produktów w tym posiłku',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.entries.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: AppColors.border(context),
            ),
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              final onTapEntry = widget.onTapEntry;
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onError,
                    semanticLabel: 'Usuń',
                  ),
                ),
                onDismissed: (_) => _handleDismiss(context, entry),
                child: _MealEntryTile(
                  entry: entry,
                  onTap: onTapEntry == null ? null : () => onTapEntry(entry),
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddProduct,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Dodaj produkt'),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealEntryTile extends StatelessWidget {
  static final _amountFormat = NumberFormat('0.###', 'pl_PL');

  final MealEntry entry;
  final VoidCallback? onTap;

  const _MealEntryTile({required this.entry, this.onTap});

  String get _amountLabel {
    if (entry.product.isQuickAdd) return 'Szybki wpis';
    if (entry.product.isRecipe) {
      final servings = entry.grams / 100;
      return Intl.plural(
        servings,
        one: '1 porcja',
        few: '${_amountFormat.format(servings)} porcje',
        other: '${_amountFormat.format(servings)} porcji',
        locale: 'pl_PL',
      );
    }
    return '${_amountFormat.format(entry.grams)} g';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = entry.product.brand?.trim();
    final description = brand == null || brand.isEmpty
        ? _amountLabel
        : '$_amountLabel • $brand';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.product.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.calories.round()} kcal',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    'B ${entry.protein.round()} • W ${entry.carbs.round()} • T ${entry.fat.round()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 17,
                color: AppColors.textSecondary(context),
                semanticLabel: 'Edytuj wpis',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${grams.round()} g',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
