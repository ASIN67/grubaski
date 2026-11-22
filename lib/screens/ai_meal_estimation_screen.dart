import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_meal_models.dart';
import '../models/meal_type.dart';
import '../providers/ai_meal_provider.dart';
import '../utils/app_colors.dart';

/// Screen allowing the user to estimate calories and macros via Gemini AI.
/// Supports text prompt, live camera photo, gallery photo, and photo with notes.
class AiMealEstimationScreen extends ConsumerStatefulWidget {
  final MealType initialMealType;
  final DateTime initialDate;

  const AiMealEstimationScreen({
    super.key,
    this.initialMealType = MealType.lunch,
    required this.initialDate,
  });

  static Future<void> open(
    BuildContext context, {
    MealType initialMealType = MealType.lunch,
    required DateTime initialDate,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiMealEstimationScreen(
          initialMealType: initialMealType,
          initialDate: initialDate,
        ),
      ),
    );
  }

  @override
  ConsumerState<AiMealEstimationScreen> createState() =>
      _AiMealEstimationScreenState();
}

class _AiMealEstimationScreenState
    extends ConsumerState<AiMealEstimationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customGramsController = TextEditingController();
  final TextEditingController _customCaloriesController =
      TextEditingController();
  final TextEditingController _customProteinController =
      TextEditingController();
  final TextEditingController _customCarbsController = TextEditingController();
  final TextEditingController _customFatController = TextEditingController();

  bool _isEditingMacros = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(aiMealProvider.notifier);
      notifier.setTargetMealType(widget.initialMealType);
      notifier.setTargetDate(widget.initialDate);
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _customNameController.dispose();
    _customGramsController.dispose();
    _customCaloriesController.dispose();
    _customProteinController.dispose();
    _customCarbsController.dispose();
    _customFatController.dispose();
    super.dispose();
  }

  void _syncControllersWithEstimation(AiMealEstimationResult result) {
    _customNameController.text = result.mealName;
    _customGramsController.text =
        result.estimatedWeightGrams.round().toString();
    _customCaloriesController.text = result.calories.round().toString();
    _customProteinController.text =
        result.proteinGrams.toStringAsFixed(1);
    _customCarbsController.text = result.carbsGrams.toStringAsFixed(1);
    _customFatController.text = result.fatGrams.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiMealProvider);
    final notifier = ref.read(aiMealProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AiMealState>(aiMealProvider, (previous, next) {
      if (previous?.estimationResult != next.estimationResult &&
          next.estimationResult != null) {
        _syncControllersWithEstimation(next.estimationResult!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Oszacuj Makro AI',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Wyczyść wszystko',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _promptController.clear();
              notifier.reset();
              setState(() {
                _isEditingMacros = false;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Banner & Info
            _buildHeaderBanner(isDark),

            const SizedBox(height: 16),

            // 2. Meal Type Selector & Date
            _buildTargetSelector(context, state, notifier, isDark),

            const SizedBox(height: 16),

            // 3. Photo Section (Camera / Gallery / Preview)
            _buildPhotoSection(context, state, notifier, isDark),

            const SizedBox(height: 14),

            // 4. Prompt Input Field
            _buildPromptInput(state, isDark),

            const SizedBox(height: 16),

            // 5. Action Button (Analyze via AI)
            _buildAnalyzeButton(state, notifier),

            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(state.errorMessage!, isDark),
            ],

            if (state.estimationResult != null) ...[
              const SizedBox(height: 24),
              _buildResultsCard(context, state, notifier, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E172E)
            : const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.smart_toy_rounded,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Wpisz opis posiłku, zrób zdjęcie aparatem lub wybierz z galerii. Gemini AI automatycznie policzy kalorie i makroskładniki.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(
    BuildContext context,
    AiMealState state,
    AiMealNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Dodaj do:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MealType>(
                value: state.targetMealType,
                isDense: true,
                isExpanded: true,
                items: MealType.values.map((type) {
                  return DropdownMenuItem<MealType>(
                    value: type,
                    child: Text(
                      type.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newType) {
                  if (newType != null) {
                    notifier.setTargetMealType(newType);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(
    BuildContext context,
    AiMealState state,
    AiMealNotifier notifier,
    bool isDark,
  ) {
    final hasImage = state.selectedImageBytes != null;

    if (hasImage) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                state.selectedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                tooltip: 'Usuń zdjęcie',
                onPressed: notifier.clearImage,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Zdjęcie załączone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Camera button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            label: const Text(
              'Zrób zdjęcie',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            onPressed: state.isLoading ? null : notifier.pickImageFromCamera,
          ),
        ),
        const SizedBox(width: 10),
        // Gallery button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
            icon: const Icon(Icons.photo_library_rounded,
                color: Color(0xFFEC4899)),
            label: const Text(
              'Z galerii',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            onPressed: state.isLoading ? null : notifier.pickImageFromGallery,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptInput(AiMealState state, bool isDark) {
    final hasImage = state.selectedImageBytes != null;

    return TextField(
      controller: _promptController,
      maxLines: 3,
      enabled: !state.isLoading,
      decoration: InputDecoration(
        hintText: hasImage
            ? 'Opcjonalny opis posiłku (np. „porcja 300g, sos na jogurcie greckim, bez cukru”)...'
            : 'Opisz posiłek (np. „3 jajka sadzone na maśle, 2 kromki chleba żytniego i pomidor”)...',
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.6,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildAnalyzeButton(AiMealState state, AiMealNotifier notifier) {
    final hasImage = state.selectedImageBytes != null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: state.isLoading
            ? null
            : () => notifier.estimateMeal(_promptController.text),
        child: state.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Gemini analizuje Twój posiłek...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    hasImage
                        ? '✨ Przeanalizuj zdjęcie i oblicz makro'
                        : '✨ Oblicz makro z opisu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorCard(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(
    BuildContext context,
    AiMealState state,
    AiMealNotifier notifier,
    bool isDark,
  ) {
    final result = state.estimationResult!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E172E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Confidence Badge & Edit Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pewność: ${result.confidence ?? "Wysoka"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  _isEditingMacros ? Icons.check_rounded : Icons.edit_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: Text(
                  _isEditingMacros ? 'Zakończ edycję' : 'Dostosuj wartości',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isEditingMacros = !_isEditingMacros;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Meal Title (Editable or Static)
          if (_isEditingMacros)
            TextField(
              controller: _customNameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa posiłku',
                isDense: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            )
          else
            Text(
              result.mealName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),

          const SizedBox(height: 14),

          // Total Calories & Estimated Weight Row
          Row(
            children: [
              Expanded(
                child: _buildResultMetricTile(
                  label: 'Kalorie',
                  value: _isEditingMacros
                      ? null
                      : '${result.calories.round()} kcal',
                  color: const Color(0xFFF97316),
                  icon: Icons.local_fire_department_rounded,
                  controller: _isEditingMacros ? _customCaloriesController : null,
                  unitSuffix: 'kcal',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResultMetricTile(
                  label: 'Szacowana waga',
                  value: _isEditingMacros
                      ? null
                      : '${result.estimatedWeightGrams.round()} g',
                  color: AppColors.primary,
                  icon: Icons.scale_rounded,
                  controller: _isEditingMacros ? _customGramsController : null,
                  unitSuffix: 'g',
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Macros Row: Białko, Węgle, Tłuszcz
          Row(
            children: [
              Expanded(
                child: _buildMacroMiniTile(
                  label: 'Białko',
                  value: _isEditingMacros ? null : '${result.proteinGrams} g',
                  color: const Color(0xFF38BDF8),
                  controller: _isEditingMacros ? _customProteinController : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroMiniTile(
                  label: 'Węgle',
                  value: _isEditingMacros ? null : '${result.carbsGrams} g',
                  color: const Color(0xFFFBBF24),
                  controller: _isEditingMacros ? _customCarbsController : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroMiniTile(
                  label: 'Tłuszcz',
                  value: _isEditingMacros ? null : '${result.fatGrams} g',
                  color: const Color(0xFFFB7185),
                  controller: _isEditingMacros ? _customFatController : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          if (result.adviceOrNotes != null &&
              result.adviceOrNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFBBF24),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.adviceOrNotes!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (result.ingredients.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Rozpoznane składniki:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...result.ingredients.map(
              (ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ing.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${ing.weightGrams.round()}g • ${ing.calories.round()} kcal',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Save to Diary Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'Dodaj do: ${state.targetMealType.displayName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onPressed: () async {
                final grams = double.tryParse(_customGramsController.text);
                final cal = double.tryParse(_customCaloriesController.text);
                final p = double.tryParse(_customProteinController.text);
                final c = double.tryParse(_customCarbsController.text);
                final f = double.tryParse(_customFatController.text);

                final success = await notifier.saveToDiary(
                  customizedMealName: _customNameController.text,
                  customizedGrams: grams,
                  customizedCalories: cal,
                  customizedProtein: p,
                  customizedCarbs: c,
                  customizedFat: f,
                );

                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dodano "${_customNameController.text.trim().isNotEmpty ? _customNameController.text.trim() : result.mealName}" do posiłku ${state.targetMealType.displayName}!',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetricTile({
    required String label,
    required String? value,
    required Color color,
    required IconData icon,
    required bool isDark,
    TextEditingController? controller,
    String? unitSuffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (controller != null)
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                suffixText: unitSuffix,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            )
          else
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroMiniTile({
    required String label,
    required String? value,
    required Color color,
    required bool isDark,
    TextEditingController? controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          if (controller != null)
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                suffixText: 'g',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            )
          else
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
