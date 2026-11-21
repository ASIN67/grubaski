import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../providers/product_search_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../utils/string_utils.dart';
import 'add_portion_sheet.dart';
import 'barcode_scanner_screen.dart';
import 'create_custom_product_screen.dart';
import 'create_recipe_screen.dart';
import 'quick_add_sheet.dart';

enum _ProductFilter {
  all('Wszystkie', 'Wyszukaj produkt lub zeskanuj kod kreskowy.'),
  custom('Własne', 'Utwórz własny produkt lub przepis.'),
  favorites('Ulubione', 'Dotknij gwiazdki przy produkcie, aby go tu zapisać.'),
  recent('Ostatnie', 'Tu pojawią się produkty dodane do posiłków tego dnia.');

  final String label;
  final String emptyMessage;

  const _ProductFilter(this.label, this.emptyMessage);
}

class AddProductScreen extends ConsumerStatefulWidget {
  final MealType initialMealType;
  final DateTime? date;
  final bool returnEntryOnAdd;

  const AddProductScreen({
    super.key,
    this.initialMealType = MealType.breakfast,
    this.date,
    this.returnEntryOnAdd = false,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _searchScope = Object();
  final _searchController = TextEditingController();
  late MealType _mealType;
  _ProductFilter _filter = _ProductFilter.all;

  DateTime get _targetDate => widget.date ?? ref.read(selectedDateProvider);

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSaved(MealEntry? entry) {
    if (mounted && entry != null && widget.returnEntryOnAdd) {
      Navigator.of(context).pop(entry);
    }
  }

  Future<void> _openBarcodeScanner() async {
    final date = _targetDate;
    final entry = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(mealType: _mealType, date: date),
      ),
    );
    _handleSaved(entry);
  }

  Future<void> _openCreateProduct({required bool recipe}) async {
    final product = await Navigator.of(context).push<FoodProduct>(
      MaterialPageRoute(
        builder: (_) => recipe
            ? const CreateRecipeScreen()
            : const CreateCustomProductScreen(),
      ),
    );
    if (mounted && product != null) {
      await _selectProduct(product);
    }
  }

  Future<void> _selectProduct(FoodProduct product) async {
    final entry = await AddPortionSheet.show(
      context,
      product: product,
      initialMealType: _mealType,
      date: _targetDate,
    );
    _handleSaved(entry);
  }

  Future<void> _quickAdd() async {
    final entry = await QuickAddSheet.show(
      context,
      date: _targetDate,
      initialMealType: _mealType,
    );
    _handleSaved(entry);
  }

  Future<void> _toggleFavorite(FoodProduct product) async {
    try {
      await ref.read(productRepositoryProvider).toggleFavorite(product);
    } catch (error) {
      debugPrint('Favorite update failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zmienić ulubionych.')),
      );
    }
  }

  List<FoodProduct> _visibleProducts(
    ProductSearchState search,
    List<MealEntry> entries,
    List<FoodProduct> catalog,
  ) {
    switch (_filter) {
      case _ProductFilter.all:
        return search.results;
      case _ProductFilter.custom:
        return search.results.where((product) => product.isCustom).toList();
      case _ProductFilter.favorites:
        return search.results.where((product) => product.isFavorite).toList();
      case _ProductFilter.recent:
        final catalogById = {
          for (final product in catalog) product.id: product
        };
        final seen = <String>{};
        final query = normalizeForSearch(search.query);
        final rawQuery = search.query.trim();
        return [
          for (final entry in entries.reversed)
            if (!entry.product.isQuickAdd &&
                seen.add(entry.product.id) &&
                (normalizeForSearch(entry.product.fullDisplayName).contains(query) ||
                    (entry.product.barcode?.contains(rawQuery) ?? false)))
              catalogById[entry.product.id] ??
                  entry.product.copyWith(isFavorite: false),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = productSearchProvider(_searchScope);
    final search = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final diary = ref.watch(diaryProvider);
    final date = widget.date ?? diary.selectedDate;
    final entries = DateFormatter.toDateKey(date) == diary.dateKey
        ? diary.entries
        : ref.watch(diaryRepositoryProvider).getEntriesForDateKey(
              DateFormatter.toDateKey(date),
            );
    final products =
        _visibleProducts(search, entries, ref.watch(localProductsProvider));
    final hasSearchText = _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj do posiłku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Skanuj kod kreskowy',
            onPressed: _openBarcodeScanner,
          ),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: _ProductFilter.values.length,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Text(
                    DateFormatter.formatPolishDisplayDate(date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final meal in MealType.values) ...[
                        ChoiceChip(
                          avatar: Icon(meal.icon, size: 16),
                          label: Text(meal.displayName),
                          selected: meal == _mealType,
                          onSelected: (_) => setState(() => _mealType = meal),
                        ),
                        if (meal != MealType.values.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Szukaj produktu lub przepisu',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: hasSearchText
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.onQueryChanged('');
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Wyczyść wyszukiwanie',
                                )
                              : null,
                        ),
                        onChanged: (query) {
                          notifier.onQueryChanged(query);
                          setState(() {});
                        },
                        onSubmitted: notifier.searchImmediate,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FilledButton.icon(
                            onPressed: _quickAdd,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Szybki wpis'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openCreateProduct(recipe: true),
                            icon: const Icon(Icons.soup_kitchen_outlined),
                            label: const Text('Nowy przepis'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openCreateProduct(recipe: false),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Własny produkt'),
                          ),
                        ],
                      ),
                      if (search.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (search.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(search.errorMessage!,
                              style: TextStyle(color: scheme.error)),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    for (final filter in _ProductFilter.values)
                      Tab(text: filter.label),
                  ],
                  onTap: (index) =>
                      setState(() => _filter = _ProductFilter.values[index]),
                ),
              ),
              if (products.isEmpty && !search.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Text(
                      search.query.isEmpty
                          ? _filter.emptyMessage
                          : 'Brak wyników dla „${search.query}”.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                sliver: SliverList.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProductTile(
                        product: product,
                        onSelect: () => _selectProduct(product),
                        onFavorite: () => _toggleFavorite(product),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final FoodProduct product;
  final VoidCallback onSelect;
  final VoidCallback onFavorite;

  const _ProductTile({
    required this.product,
    required this.onSelect,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final format = NumberFormat('0.#', 'pl_PL');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              product.isRecipe
                  ? Icons.soup_kitchen_outlined
                  : Icons.restaurant_menu_rounded,
              color: scheme.onPrimaryContainer,
              size: 20,
            ),
          ),
        ),
        title: Text(
          product.fullDisplayName,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${format.format(product.caloriesPer100g)} kcal / '
                '${product.usesPortions ? 'porcja' : '100 g'}',
                style: TextStyle(
                  color: AppColors.caloriesOn(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  Text('B ${format.format(product.proteinPer100g)} g',
                      semanticsLabel:
                          'Białko ${format.format(product.proteinPer100g)} gramów',
                      style: TextStyle(color: AppColors.proteinOn(context))),
                  Text('W ${format.format(product.carbsPer100g)} g',
                      semanticsLabel:
                          'Węglowodany ${format.format(product.carbsPer100g)} gramów',
                      style: TextStyle(color: AppColors.carbsOn(context))),
                  Text('T ${format.format(product.fatPer100g)} g',
                      semanticsLabel:
                          'Tłuszcze ${format.format(product.fatPer100g)} gramów',
                      style: TextStyle(color: AppColors.fatOn(context))),
                ],
              ),
            ],
          ),
        ),
        onTap: onSelect,
        trailing: IconButton(
          isSelected: product.isFavorite,
          tooltip:
              product.isFavorite ? 'Usuń z ulubionych' : 'Dodaj do ulubionych',
          onPressed: onFavorite,
          icon: const Icon(Icons.star_border_rounded),
          selectedIcon:
              Icon(Icons.star_rounded, color: AppColors.carbsOn(context)),
        ),
      ),
    );
  }
}
