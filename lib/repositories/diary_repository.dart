import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import '../utils/date_formatter.dart';

/// Aggregated nutritional metrics and meal groupings for a single day.
class DailyDiarySummary {
  final String dateKey;
  final List<MealEntry> allEntries;
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

  const DailyDiarySummary({
    required this.dateKey,
    required this.allEntries,
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
  });

  /// Factory constructor that computes aggregated macros and groupings from a list of entries.
  factory DailyDiarySummary.fromEntries(
      String dateKey, List<MealEntry> entries) {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;

    final entriesByMeal = <MealType, List<MealEntry>>{
      for (final type in MealType.values) type: <MealEntry>[],
    };

    final caloriesByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };

    final proteinByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };

    final carbsByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };

    final fatByMeal = <MealType, double>{
      for (final type in MealType.values) type: 0.0,
    };

    for (final entry in entries) {
      final cal = entry.calories;
      final p = entry.protein;
      final c = entry.carbs;
      final f = entry.fat;
      final fib = entry.fiber;

      totalCalories += cal;
      totalProtein += p;
      totalCarbs += c;
      totalFat += f;
      totalFiber += fib;

      final mealType = entry.mealType;
      entriesByMeal[mealType]?.add(entry);
      caloriesByMeal[mealType] = (caloriesByMeal[mealType] ?? 0.0) + cal;
      proteinByMeal[mealType] = (proteinByMeal[mealType] ?? 0.0) + p;
      carbsByMeal[mealType] = (carbsByMeal[mealType] ?? 0.0) + c;
      fatByMeal[mealType] = (fatByMeal[mealType] ?? 0.0) + f;
    }

    return DailyDiarySummary(
      dateKey: dateKey,
      allEntries: List.unmodifiable(entries),
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFiber,
      entriesByMeal: Map.unmodifiable(entriesByMeal),
      caloriesByMeal: Map.unmodifiable(caloriesByMeal),
      proteinByMeal: Map.unmodifiable(proteinByMeal),
      carbsByMeal: Map.unmodifiable(carbsByMeal),
      fatByMeal: Map.unmodifiable(fatByMeal),
    );
  }

  /// Empty summary for days without logged meals.
  factory DailyDiarySummary.empty(String dateKey) {
    return DailyDiarySummary.fromEntries(dateKey, const []);
  }
}

/// Repository responsible for logging meals, retrieving daily diaries,
/// computing day macros, and performing diary manipulation (copy, delete, edit).
class DiaryRepository {
  final HiveService _hiveService;
  static const _uuid = Uuid();
  static const String deletedMealEntryIdsKey = 'deleted_meal_entry_ids';

  DiaryRepository({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService.instance;

  Box<MealEntry> get _box => _hiveService.mealEntriesBox;

  Box<dynamic>? get _settingsBoxOrNull {
    if (!Hive.isBoxOpen(HiveService.settingsBoxName)) return null;
    try {
      return _hiveService.settingsBox;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordDeletedIds(Iterable<String> ids) async {
    final settingsBox = _settingsBoxOrNull;
    if (settingsBox == null) return;

    final toRecord = ids.where((id) => id.isNotEmpty).toList();
    if (toRecord.isEmpty) return;

    final raw = settingsBox.get(deletedMealEntryIdsKey);
    final updated = <String>{
      if (raw is List) ...raw.map((e) => e.toString()),
      ...toRecord,
    };
    await settingsBox.put(deletedMealEntryIdsKey, updated.toList());
  }

  Future<void> _clearDeletedId(String id) async {
    final settingsBox = _settingsBoxOrNull;
    if (settingsBox == null) return;

    final raw = settingsBox.get(deletedMealEntryIdsKey);
    if (raw is! List) return;

    final updated = raw.map((e) => e.toString()).toSet();
    if (!updated.remove(id)) return;

    if (updated.isEmpty) {
      await settingsBox.delete(deletedMealEntryIdsKey);
    } else {
      await settingsBox.put(deletedMealEntryIdsKey, updated.toList());
    }
  }

  /// Returns all meal entries in storage.
  List<MealEntry> getAllEntries() {
    return _box.values.toList();
  }

  /// Returns all meal entries logged for a specific date key (YYYY-MM-DD).
  List<MealEntry> getEntriesForDateKey(String dateKey) {
    return _box.values.where((entry) => entry.dateKey == dateKey).toList();
  }

  /// Returns all meal entries logged for a specific [DateTime].
  List<MealEntry> getEntriesForDate(DateTime date) {
    return getEntriesForDateKey(DateFormatter.toDateKey(date));
  }

  /// Returns entries for a specific meal category on a given date.
  List<MealEntry> getEntriesForMeal(String dateKey, MealType mealType) {
    return _box.values
        .where((e) => e.dateKey == dateKey && e.mealType == mealType)
        .toList();
  }

  /// Retrieves a single meal entry by its unique [id].
  MealEntry? getEntryById(String id) {
    return _box.get(id);
  }

  /// Returns a complete [DailyDiarySummary] containing macro totals and meal breakdowns.
  DailyDiarySummary getDailySummary(String dateKey) {
    final entries = getEntriesForDateKey(dateKey);
    return DailyDiarySummary.fromEntries(dateKey, entries);
  }

  /// Returns a complete [DailyDiarySummary] for a [DateTime].
  DailyDiarySummary getDailySummaryForDate(DateTime date) {
    return getDailySummary(DateFormatter.toDateKey(date));
  }

  /// Adds a new food item into a meal on the given date and saves it to storage.
  Future<MealEntry> addEntry({
    required String dateKey,
    required MealType mealType,
    required FoodProduct product,
    required double grams,
  }) async {
    final entry = MealEntry(
      id: _uuid.v4(),
      dateKey: dateKey,
      mealType: mealType,
      grams: grams,
      product: product,
    );

    await saveEntry(entry);
    return entry;
  }

  /// Saves or updates a [MealEntry] in storage using its [MealEntry.id] as key.
  Future<void> saveEntry(MealEntry entry) async {
    await _box.put(entry.id, entry);
    await _clearDeletedId(entry.id);
  }

  /// Alias for [saveEntry].
  Future<void> updateEntry(MealEntry entry) async {
    await saveEntry(entry);
  }

  /// Updates the portion grams for an existing entry.
  Future<MealEntry?> updateEntryGrams(String entryId, double newGrams) {
    return updateEntryDetails(entryId: entryId, grams: newGrams);
  }

  /// Updates an entry in place, preserving its ID and diary day.
  Future<MealEntry?> updateEntryDetails({
    required String entryId,
    required double grams,
    MealType? mealType,
    FoodProduct? product,
  }) async {
    final existing = getEntryById(entryId);
    if (existing == null) return null;

    final updated = existing.copyWith(
      grams: grams,
      mealType: mealType,
      product: product,
    );
    await saveEntry(updated);
    return updated;
  }

  /// Deletes a specific meal entry by its [id].
  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    await _recordDeletedIds([id]);
  }

  /// Deletes all entries for a specific meal on a given date.
  Future<void> deleteEntriesForMeal(String dateKey, MealType mealType) async {
    final toDelete = _box.values
        .where((e) => e.dateKey == dateKey && e.mealType == mealType)
        .map((e) => e.id)
        .toList();

    await _box.deleteAll(toDelete);
    await _recordDeletedIds(toDelete);
  }

  /// Deletes all meal entries logged for an entire day.
  Future<void> deleteEntriesForDate(String dateKey) async {
    final toDelete = _box.values
        .where((e) => e.dateKey == dateKey)
        .map((e) => e.id)
        .toList();

    await _box.deleteAll(toDelete);
    await _recordDeletedIds(toDelete);
  }

  /// Copies all entries from [sourceDateKey] into [targetDateKey] with new unique IDs.
  Future<List<MealEntry>> copyDayEntries({
    required String sourceDateKey,
    required String targetDateKey,
  }) async {
    return _copyEntries(
      getEntriesForDateKey(sourceDateKey),
      targetDateKey: targetDateKey,
    );
  }

  /// Appends a meal's entries to a different day or meal category.
  Future<List<MealEntry>> copyMealEntries({
    required String sourceDateKey,
    required MealType sourceMealType,
    required String targetDateKey,
    required MealType targetMealType,
  }) async {
    if (sourceDateKey == targetDateKey && sourceMealType == targetMealType) {
      return const [];
    }

    return _copyEntries(
      getEntriesForMeal(sourceDateKey, sourceMealType),
      targetDateKey: targetDateKey,
      targetMealType: targetMealType,
    );
  }

  /// Copies specific selected entries to a [targetDateKey], optionally reassigning their [MealType].
  Future<List<MealEntry>> copyEntriesToMeal({
    required List<String> entryIds,
    required String targetDateKey,
    MealType? targetMealType,
  }) async {
    return _copyEntries(
      entryIds.map(getEntryById).whereType<MealEntry>(),
      targetDateKey: targetDateKey,
      targetMealType: targetMealType,
    );
  }

  Future<List<MealEntry>> _copyEntries(
    Iterable<MealEntry> entries, {
    required String targetDateKey,
    MealType? targetMealType,
  }) async {
    final copies = [
      for (final entry in entries)
        entry.copyWith(
          id: _uuid.v4(),
          dateKey: targetDateKey,
          mealType: targetMealType,
        ),
    ];

    if (copies.isNotEmpty) {
      await _box.putAll({for (final entry in copies) entry.id: entry});
    }
    return copies;
  }

  /// Reactive stream yielding updated entries for [dateKey] whenever the box changes.
  Stream<List<MealEntry>> watchEntriesForDate(String dateKey) async* {
    yield getEntriesForDateKey(dateKey);
    yield* _box.watch().map((_) => getEntriesForDateKey(dateKey));
  }

  /// Reactive stream yielding updated [DailyDiarySummary] whenever meal entries change.
  Stream<DailyDiarySummary> watchDailySummary(String dateKey) async* {
    yield getDailySummary(dateKey);
    yield* _box.watch().map((_) => getDailySummary(dateKey));
  }

  /// Provides a [ValueListenable] for Flutter UI widgets.
  ValueListenable<Box<MealEntry>> get entriesListenable {
    return _box.listenable();
  }
}
