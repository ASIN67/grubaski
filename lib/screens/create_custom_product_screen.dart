import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/food_product.dart';
import '../services/hive_service.dart';
import '../utils/app_colors.dart';

/// Screen allowing the user to create and save a custom food product.
/// Supports pre-filled barcodes from barcode scanner.
class CreateCustomProductScreen extends StatefulWidget {
  final String? initialBarcode;

  const CreateCustomProductScreen({
    super.key,
    this.initialBarcode,
  });

  @override
  State<CreateCustomProductScreen> createState() =>
      _CreateCustomProductScreenState();
}

class _CreateCustomProductScreenState extends State<CreateCustomProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _servingSizeController;
  late final TextEditingController _servingNameController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _barcodeController =
        TextEditingController(text: widget.initialBarcode ?? '');
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _fiberController = TextEditingController();
    _servingSizeController = TextEditingController(text: '100');
    _servingNameController = TextEditingController();

    _caloriesController.addListener(_onMacroChanged);
    _proteinController.addListener(_onMacroChanged);
    _carbsController.addListener(_onMacroChanged);
    _fatController.addListener(_onMacroChanged);
  }

  void _onMacroChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _caloriesController.removeListener(_onMacroChanged);
    _proteinController.removeListener(_onMacroChanged);
    _carbsController.removeListener(_onMacroChanged);
    _fatController.removeListener(_onMacroChanged);
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _servingSizeController.dispose();
    _servingNameController.dispose();
    super.dispose();
  }

  double _parseNum(String text) {
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final id = uuid.v4();

      final barcodeText = _barcodeController.text.trim();
      final brandText = _brandController.text.trim();
      final servingNameText = _servingNameController.text.trim();
      final fiberText = _fiberController.text.trim();

      final product = FoodProduct(
        id: id,
        barcode: barcodeText.isNotEmpty ? barcodeText : null,
        name: _nameController.text.trim(),
        brand: brandText.isNotEmpty ? brandText : null,
        caloriesPer100g: _parseNum(_caloriesController.text),
        proteinPer100g: _parseNum(_proteinController.text),
        carbsPer100g: _parseNum(_carbsController.text),
        fatPer100g: _parseNum(_fatController.text),
        fiberPer100g: fiberText.isNotEmpty ? _parseNum(fiberText) : null,
        servingSizeGrams: _parseNum(_servingSizeController.text) > 0
            ? _parseNum(_servingSizeController.text)
            : 100.0,
        servingName: servingNameText.isNotEmpty ? servingNameText : null,
        isCustom: true,
      );

      // Save directly to Hive box
      await HiveService.instance.foodProductsBox.put(product.id, product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dodano produkt: ${product.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(product);
      }
    } catch (e) {
      debugPrint('Failed to save custom product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać produktu.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calories = _parseNum(_caloriesController.text);
    final protein = _parseNum(_proteinController.text);
    final carbs = _parseNum(_carbsController.text);
    final fat = _parseNum(_fatController.text);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Dodaj własny produkt',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Macro Preview Header Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.heroCardGradient : null,
                  color: isDark ? null : AppColors.primaryContainerLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie w 100 g',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: AppColors.caloriesOn(context),
                              size: 28,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${calories.toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildPreviewBadge(
                              label: 'B',
                              value: '${protein.toStringAsFixed(1)}g',
                              color: AppColors.proteinOn(context),
                            ),
                            _buildPreviewBadge(
                              label: 'W',
                              value: '${carbs.toStringAsFixed(1)}g',
                              color: AppColors.carbsOn(context),
                            ),
                            _buildPreviewBadge(
                              label: 'T',
                              value: '${fat.toStringAsFixed(1)}g',
                              color: AppColors.fatOn(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Podstawowe informacje
              _buildSectionHeader('Podstawowe informacje', Icons.info_outline),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa produktu *',
                  hintText: 'np. Twaróg półtłusty',
                  prefixIcon: Icon(Icons.restaurant),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nazwa produktu jest wymagana';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marka / Producent',
                        hintText: 'np. Piątnica',
                        prefixIcon: Icon(Icons.business),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Kod kreskowy',
                        hintText: 'EAN',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: Wartości odżywcze na 100g
              _buildSectionHeader(
                  'Wartości odżywcze w 100 g', Icons.analytics_outlined),
              const SizedBox(height: 10),

              TextFormField(
                controller: _caloriesController,
                decoration: InputDecoration(
                  labelText: 'Kalorie (kcal) *',
                  hintText: '0',
                  prefixIcon: Icon(
                    Icons.local_fire_department,
                    color: AppColors.caloriesOn(context),
                  ),
                  suffixText: 'kcal',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+([.,]\d{0,2})?')),
                ],
                validator: (val) =>
                    _validateRequiredPositiveNum(val, 'Kalorie'),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: InputDecoration(
                        labelText: 'Białko *',
                        hintText: '0,0',
                        prefixIcon: Icon(Icons.fitness_center,
                            color: AppColors.proteinOn(context)),
                        suffixText: 'g',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,2})?')),
                      ],
                      validator: (val) =>
                          _validateRequiredPositiveNum(val, 'Białko'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: InputDecoration(
                        labelText: 'Węglowodany *',
                        hintText: '0,0',
                        prefixIcon: Icon(Icons.grain,
                            color: AppColors.carbsOn(context)),
                        suffixText: 'g',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,2})?')),
                      ],
                      validator: (val) =>
                          _validateRequiredPositiveNum(val, 'Węglowodany'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: InputDecoration(
                        labelText: 'Tłuszcze *',
                        hintText: '0,0',
                        prefixIcon: Icon(Icons.opacity,
                            color: AppColors.fatOn(context)),
                        suffixText: 'g',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,2})?')),
                      ],
                      validator: (val) =>
                          _validateRequiredPositiveNum(val, 'Tłuszcze'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fiberController,
                      decoration: InputDecoration(
                        labelText: 'Błonnik (opcja)',
                        hintText: '0,0',
                        prefixIcon: Icon(Icons.grass,
                            color: AppColors.fiberOn(context)),
                        suffixText: 'g',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,2})?')),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Section: Sugerowana porcja
              _buildSectionHeader(
                  'Sugerowana porcja (opcjonalnie)', Icons.straighten),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _servingSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Waga porcji (g)',
                        hintText: '100',
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'g',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,1})?')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _servingNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa porcji',
                        hintText: 'np. 1 kromka, 1 sztuka',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving ? 'Zapisywanie...' : 'Zapisz produkt',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  String? _validateRequiredPositiveNum(String? val, String fieldName) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName jest wymagane';
    }
    final parsed = double.tryParse(val.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return 'Podaj poprawną wartość (>= 0)';
    }
    return null;
  }
}
