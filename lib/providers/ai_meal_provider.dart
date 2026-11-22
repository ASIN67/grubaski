import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_meal_models.dart';
import '../models/meal_type.dart';
import '../repositories/diary_repository.dart';
import '../repositories/product_repository.dart';
import '../services/ai_meal_service.dart';
import 'diary_provider.dart';

final aiMealServiceProvider = Provider<AiMealService>((ref) {
  final service = AiMealService();
  service.init();
  return service;
});

class AiMealState {
  final bool isLoading;
  final String? errorMessage;
  final AiMealEstimationResult? estimationResult;
  final Uint8List? selectedImageBytes;
  final String? selectedImagePath;
  final MealType targetMealType;
  final DateTime targetDate;

  const AiMealState({
    this.isLoading = false,
    this.errorMessage,
    this.estimationResult,
    this.selectedImageBytes,
    this.selectedImagePath,
    this.targetMealType = MealType.lunch,
    required this.targetDate,
  });

  AiMealState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AiMealEstimationResult? estimationResult,
    bool clearEstimation = false,
    Uint8List? selectedImageBytes,
    String? selectedImagePath,
    bool clearImage = false,
    MealType? targetMealType,
    DateTime? targetDate,
  }) {
    return AiMealState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      estimationResult: clearEstimation
          ? null
          : (estimationResult ?? this.estimationResult),
      selectedImageBytes: clearImage
          ? null
          : (selectedImageBytes ?? this.selectedImageBytes),
      selectedImagePath: clearImage
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      targetMealType: targetMealType ?? this.targetMealType,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}

class AiMealNotifier extends StateNotifier<AiMealState> {
  final AiMealService _service;
  final DiaryRepository _diaryRepo;
  final ProductRepository _productRepo;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  AiMealNotifier(
    this._service,
    this._diaryRepo,
    this._productRepo,
    this._ref,
  ) : super(AiMealState(targetDate: DateTime.now()));

  void setTargetMealType(MealType mealType) {
    state = state.copyWith(targetMealType: mealType);
  }

  void setTargetDate(DateTime date) {
    state = state.copyWith(targetDate: date);
  }

  /// Picks photo from camera directly.
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      state = state.copyWith(
        selectedImageBytes: bytes,
        selectedImagePath: file.path,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Nie udało się zrobić zdjęcia z aparatu: $e',
      );
    }
  }

  /// Picks photo from gallery.
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      state = state.copyWith(
        selectedImageBytes: bytes,
        selectedImagePath: file.path,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Nie udało się wybrać zdjęcia z galerii: $e',
      );
    }
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void clearResult() {
    state = state.copyWith(clearEstimation: true, clearError: true);
  }

  void reset() {
    state = AiMealState(
      targetDate: state.targetDate,
      targetMealType: state.targetMealType,
    );
  }

  /// Runs Gemini AI meal estimation for the current input (text, image, or both).
  Future<void> estimateMeal(String textPrompt) async {
    final cleanPrompt = textPrompt.trim();
    if (cleanPrompt.isEmpty && state.selectedImageBytes == null) {
      state = state.copyWith(
        errorMessage: 'Wpisz opis dania lub dodaj zdjęcie z aparatu/galerii.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearEstimation: true,
    );

    try {
      final result = await _service.estimateMeal(
        textPrompt: cleanPrompt.isNotEmpty ? cleanPrompt : null,
        imageBytes: state.selectedImageBytes,
      );

      state = state.copyWith(
        isLoading: false,
        estimationResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Saves the current estimation result into the user's diary as a meal entry.
  Future<bool> saveToDiary({
    String? customizedMealName,
    double? customizedGrams,
    double? customizedCalories,
    double? customizedProtein,
    double? customizedCarbs,
    double? customizedFat,
  }) async {
    final estimation = state.estimationResult;
    if (estimation == null) return false;

    try {
      final finalName = customizedMealName?.trim().isNotEmpty == true
          ? customizedMealName!.trim()
          : estimation.mealName;
      final finalGrams = customizedGrams ?? estimation.estimatedWeightGrams;
      final finalCalories = customizedCalories ?? estimation.calories;
      final finalProtein = customizedProtein ?? estimation.proteinGrams;
      final finalCarbs = customizedCarbs ?? estimation.carbsGrams;
      final finalFat = customizedFat ?? estimation.fatGrams;

      // Create FoodProduct
      final product = await _productRepo.createCustomProduct(
        name: finalName,
        brand: 'AI Oszacowanie',
        caloriesPer100g: finalGrams > 0
            ? ((finalCalories * 100.0) / finalGrams).roundToDouble()
            : finalCalories.roundToDouble(),
        proteinPer100g: finalGrams > 0
            ? ((finalProtein * 100.0) / finalGrams)
            : finalProtein,
        carbsPer100g: finalGrams > 0
            ? ((finalCarbs * 100.0) / finalGrams)
            : finalCarbs,
        fatPer100g: finalGrams > 0
            ? ((finalFat * 100.0) / finalGrams)
            : finalFat,
        servingSizeGrams: finalGrams > 0 ? finalGrams : 100.0,
        servingName: 'porcja',
      );

      // Save to diary
      final dateKey =
          '${state.targetDate.year}-${state.targetDate.month.toString().padLeft(2, '0')}-${state.targetDate.day.toString().padLeft(2, '0')}';

      await _diaryRepo.addEntry(
        dateKey: dateKey,
        mealType: state.targetMealType,
        product: product,
        grams: finalGrams > 0 ? finalGrams : 100.0,
      );

      // Trigger UI refreshes safely
      try {
        _ref.read(diaryProvider.notifier).refresh();
      } catch (_) {}

      return true;
    } catch (e, stack) {
      debugPrint('Failed to save AI meal to diary: $e\n$stack');
      if (mounted) {
        state = state.copyWith(errorMessage: 'Nie udało się zapisać w dzienniku: $e');
      }
      return false;
    }
  }
}

final aiMealProvider =
    StateNotifierProvider<AiMealNotifier, AiMealState>((ref) {
  final service = ref.watch(aiMealServiceProvider);
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final productRepo = ProductRepository();
  return AiMealNotifier(service, diaryRepo, productRepo, ref);
});
