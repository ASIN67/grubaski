import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/diary_repository.dart';
import '../utils/date_formatter.dart';

/// Provider for [DiaryRepository] dependency injection.
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

/// Immutable state encapsulating the currently selected diary date,
/// filtered meal entries, computed nutritional macro totals, and meal-specific breakdowns.
class DiaryState {
  final DateTime selectedDate;
  final String dateKey;
  final List<MealEntry> entries;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final Map<MealType, List<MealEntry>> entriesByMeal;
  final Map<MealType, double> caloriesByMeal;
  final Map<MealType, double> proteinByMeal;
  final Map<MealType, double> carbsByMeal;
  final Map<MealType, double> fatByMeal;
  final MealEntry? lastRemovedEntry;

  const DiaryState({
    required this.selectedDate,
    required this.dateKey,
    required this.entries,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.entriesByMeal,
    required this.caloriesByMeal,
    required this.proteinByMeal,
    required this.carbsByMeal,
    required this.fatByMeal,
    this.lastRemovedEntry,
  });

  /// Factory constructing [DiaryState] from raw entries and a selected [DateTime].
  factory DiaryState.fromEntries({
    required DateTime selectedDate,
    required List<MealEntry> entries,
    MealEntry? lastRemovedEntry,
  }) {
    final dateKey = DateFormatter.toDateKey(selectedDate);

    double totalCal = 0.0;
    double totalP = 0.0;
    double totalC = 0.0;
    double totalF = 0.0;
    double totalFib = 0.0;

    final byMeal = <MealType, List<MealEntry>>{
      for (final type in MealType.values) type: <MealEntry>[],
    };

    final calByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };
    final pByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };
    final cByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };
    final fByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };

    for (final entry in entries) {
      final c = entry.calories;
      final p = entry.protein;
      final cb = entry.carbs;
      final f = entry.fat;
      final fib = entry.fiber;

      totalCal += c;
      totalP += p;
      totalC += cb;
      totalF += f;
      totalFib += fib;

      final type = entry.mealType;
      byMeal[type]?.add(entry);
      calByMeal[type] = (calByMeal[type] ?? 0.0) + c;
      pByMeal[type] = (pByMeal[type] ?? 0.0) + p;
      cByMeal[type] = (cByMeal[type] ?? 0.0) + cb;
      fByMeal[type] = (fByMeal[type] ?? 0.0) + f;
    }

    return DiaryState(
      selectedDate: selectedDate,
      dateKey: dateKey,
      entries: List.unmodifiable(entries),
      totalCalories: totalCal,
      totalProtein: totalP,
      totalCarbs: totalC,
      totalFat: totalF,
      totalFiber: totalFib,
      entriesByMeal: Map.unmodifiable(byMeal),
      caloriesByMeal: Map.unmodifiable(calByMeal),
      proteinByMeal: Map.unmodifiable(pByMeal),
      carbsByMeal: Map.unmodifiable(cByMeal),
      fatByMeal: Map.unmodifiable(fByMeal),
      lastRemovedEntry: lastRemovedEntry,
    );
  }

  DiaryState copyWith({
    DateTime? selectedDate,
    String? dateKey,
    List<MealEntry>? entries,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    double? totalFiber,
    Map<MealType, List<MealEntry>>? entriesByMeal,
    Map<MealType, double>? caloriesByMeal,
    Map<MealType, double>? proteinByMeal,
    Map<MealType, double>? carbsByMeal,
    Map<MealType, double>? fatByMeal,
    MealEntry? lastRemovedEntry,
    bool clearLastRemovedEntry = false,
  }) {
    return DiaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      dateKey: dateKey ?? this.dateKey,
      entries: entries ?? this.entries,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalFiber: totalFiber ?? this.totalFiber,
      entriesByMeal: entriesByMeal ?? this.entriesByMeal,
      caloriesByMeal: caloriesByMeal ?? this.caloriesByMeal,
      proteinByMeal: proteinByMeal ?? this.proteinByMeal,
      carbsByMeal: carbsByMeal ?? this.carbsByMeal,
      fatByMeal: fatByMeal ?? this.fatByMeal,
      lastRemovedEntry: clearLastRemovedEntry
          ? null
          : (lastRemovedEntry ?? this.lastRemovedEntry),
    );
  }
}

/// StateNotifier responsible for managing the active diary date,
/// CRUD operations on food entries, and undo mechanisms.
class DiaryNotifier extends StateNotifier<DiaryState> {
  final DiaryRepository _repository;

  DiaryNotifier(this._repository)
      : super(_initState(_repository, DateTime.now()));

  static DiaryState _initState(DiaryRepository repo, DateTime date) {
    final key = DateFormatter.toDateKey(date);
    final entries = repo.getEntriesForDateKey(key);
    return DiaryState.fromEntries(
      selectedDate: date,
      entries: entries,
    );
  }

  /// Sets the currently active diary date and reloads entries for that day.
  void setSelectedDate(DateTime date) {
    final currentKey = state.dateKey;
    final newKey = DateFormatter.toDateKey(date);

    if (currentKey == newKey &&
        state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }

    final entries = _repository.getEntriesForDateKey(newKey);
    state = DiaryState.fromEntries(
      selectedDate: date,
      entries: entries,
      lastRemovedEntry: null,
    );
  }

  /// Advances date by 1 day.
  void goToNextDay() {
    setSelectedDate(DateUtils.addDaysToDate(state.selectedDate, 1));
  }

  /// Moves date back by 1 day.
  void goToPreviousDay() {
    setSelectedDate(DateUtils.addDaysToDate(state.selectedDate, -1));
  }

  /// Resets selection to today's date.
  void goToToday() {
    setSelectedDate(DateTime.now());
  }

  /// Reloads entries for the currently selected date.
  void refresh() {
    final entries = _repository.getEntriesForDateKey(state.dateKey);
    state = DiaryState.fromEntries(
      selectedDate: state.selectedDate,
      entries: entries,
      lastRemovedEntry: state.lastRemovedEntry,
    );
  }

  /// Adds a new product entry to a meal on the currently selected date.
  Future<MealEntry> addEntry({
    required MealType mealType,
    required FoodProduct product,
    required double grams,
    DateTime? date,
  }) async {
    final targetDate = date ?? state.selectedDate;
    final targetKey = DateFormatter.toDateKey(targetDate);

    final entry = await _repository.addEntry(
      dateKey: targetKey,
      mealType: mealType,
      product: product,
      grams: grams,
    );

    if (targetKey == state.dateKey) {
      refresh();
    }

    return entry;
  }

  /// Removes a meal entry and stores it in [state.lastRemovedEntry] for undo support.
  Future<MealEntry?> removeEntry(String id) async {
    final entryToRemove = _repository.getEntryById(id);
    if (entryToRemove == null) return null;

    await _repository.deleteEntry(id);

    final updatedEntries = _repository.getEntriesForDateKey(state.dateKey);
    state = DiaryState.fromEntries(
      selectedDate: state.selectedDate,
      entries: updatedEntries,
      lastRemovedEntry: entryToRemove,
    );

    return entryToRemove;
  }

  /// Restores the last removed meal entry back into storage and current state.
  Future<MealEntry?> undoRemoveEntry() async {
    final entryToRestore = state.lastRemovedEntry;
    if (entryToRestore == null) return null;

    await _repository.saveEntry(entryToRestore);

    final updatedEntries = _repository.getEntriesForDateKey(state.dateKey);
    state = DiaryState.fromEntries(
      selectedDate: state.selectedDate,
      entries: updatedEntries,
      lastRemovedEntry: null,
    );

    return entryToRestore;
  }

  /// Clears undo history without restoring.
  void clearUndo() {
    if (state.lastRemovedEntry != null) {
      state = state.copyWith(clearLastRemovedEntry: true);
    }
  }

  /// Updates portion weight for an existing entry.
  Future<MealEntry?> updateEntryGrams(String id, double newGrams) async {
    final updated = await _repository.updateEntryGrams(id, newGrams);
    if (updated != null && updated.dateKey == state.dateKey) {
      refresh();
    }
    return updated;
  }

  Future<MealEntry?> updateEntryPortion({
    required String id,
    required double grams,
    required MealType mealType,
  }) async {
    final updated = await _repository.updateEntryDetails(
      entryId: id,
      grams: grams,
      mealType: mealType,
    );
    if (updated != null && updated.dateKey == state.dateKey) {
      refresh();
    }
    return updated;
  }

  Future<MealEntry?> updateQuickEntry({
    required String id,
    required FoodProduct product,
    required MealType mealType,
  }) async {
    final updated = await _repository.updateEntryDetails(
      entryId: id,
      grams: 100,
      mealType: mealType,
      product: product,
    );
    if (updated != null && updated.dateKey == state.dateKey) {
      refresh();
    }
    return updated;
  }

  /// Appends the source meal to the chosen day and meal category.
  Future<List<MealEntry>> copyMeal({
    required DateTime sourceDate,
    required MealType sourceMealType,
    required DateTime targetDate,
    required MealType targetMealType,
  }) async {
    final targetKey = DateFormatter.toDateKey(targetDate);
    final copies = await _repository.copyMealEntries(
      sourceDateKey: DateFormatter.toDateKey(sourceDate),
      sourceMealType: sourceMealType,
      targetDateKey: targetKey,
      targetMealType: targetMealType,
    );
    if (copies.isNotEmpty && targetKey == state.dateKey) {
      refresh();
    }
    return copies;
  }

  /// Copies all entries from the currently selected day to [targetDate].
  Future<List<MealEntry>> copyCurrentDayTo(DateTime targetDate) async {
    final targetKey = DateFormatter.toDateKey(targetDate);
    final copies = await _repository.copyDayEntries(
      sourceDateKey: state.dateKey,
      targetDateKey: targetKey,
    );
    return copies;
  }
}

/// Global provider for [DiaryNotifier] state.
final diaryProvider = StateNotifierProvider<DiaryNotifier, DiaryState>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return DiaryNotifier(repo);
});

/// Extracted provider for the selected date.
final selectedDateProvider = Provider<DateTime>((ref) {
  return ref.watch(diaryProvider.select((s) => s.selectedDate));
});

/// Extracted provider for the current date key ('YYYY-MM-DD').
final selectedDateKeyProvider = Provider<String>((ref) {
  return ref.watch(diaryProvider.select((s) => s.dateKey));
});

/// Extracted provider for the list of entries on the selected day.
final diaryEntriesProvider = Provider<List<MealEntry>>((ref) {
  return ref.watch(diaryProvider.select((s) => s.entries));
});

/// Extracted provider for entries of a specific meal type on the selected day.
final mealEntriesFamily =
    Provider.family<List<MealEntry>, MealType>((ref, mealType) {
  final state = ref.watch(diaryProvider);
  return state.entriesByMeal[mealType] ?? const [];
});

/// Extracted provider for total calories of a specific meal type on the selected day.
final mealCaloriesFamily = Provider.family<double, MealType>((ref, mealType) {
  final state = ref.watch(diaryProvider);
  return state.caloriesByMeal[mealType] ?? 0.0;
});
