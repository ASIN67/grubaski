import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/hive_service.dart';

/// Repository managing user body weight measurements, progress logs,
/// and chronological weight history.
class WeightRepository {
  final HiveService _hiveService;
  static const _uuid = Uuid();

  WeightRepository({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService.instance;

  Box<WeightEntry> get _box => _hiveService.weightEntriesBox;

  /// Retrieves all recorded weight entries, sorted chronologically.
  /// If [ascending] is true, oldest entries appear first; otherwise newest first.
  List<WeightEntry> getAllWeightEntries({bool ascending = false}) {
    final entries = _box.values.toList();
    entries.sort((a, b) =>
        ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    return entries;
  }

  /// Retrieves the most recent weight entry, or null if no weigh-ins exist.
  WeightEntry? getLatestWeightEntry() {
    final entries = getAllWeightEntries(ascending: false);
    return entries.isEmpty ? null : entries.first;
  }

  /// Retrieves the earliest recorded weight entry, or null if no weigh-ins exist.
  WeightEntry? getEarliestWeightEntry() {
    final entries = getAllWeightEntries(ascending: true);
    return entries.isEmpty ? null : entries.first;
  }

  /// Retrieves a specific entry by its unique [id].
  WeightEntry? getEntryById(String id) {
    return _box.get(id);
  }

  /// Searches for an existing weight entry recorded on the same calendar day
  /// as [date] (matching year, month, day).
  WeightEntry? getEntryForDate(DateTime date) {
    final targetY = date.year;
    final targetM = date.month;
    final targetD = date.day;

    for (final entry in _box.values) {
      if (entry.date.year == targetY &&
          entry.date.month == targetM &&
          entry.date.day == targetD) {
        return entry;
      }
    }
    return null;
  }

  /// Records a new weight measurement.
  /// If [updateExistingSameDay] is true and a measurement was already logged
  /// on the same day, updates that day's entry rather than creating a duplicate.
  Future<WeightEntry> logWeight({
    required double weightKg,
    DateTime? date,
    bool updateExistingSameDay = true,
  }) async {
    final entryDate = date ?? DateTime.now();

    if (updateExistingSameDay) {
      final existing = getEntryForDate(entryDate);
      if (existing != null) {
        final updated = existing.copyWith(
          weightKg: weightKg,
          date: entryDate,
        );
        await saveWeightEntry(updated);
        return updated;
      }
    }

    final newEntry = WeightEntry(
      id: _uuid.v4(),
      date: entryDate,
      weightKg: weightKg,
    );

    await saveWeightEntry(newEntry);
    return newEntry;
  }

  /// Saves or updates a [WeightEntry] in local storage using its [WeightEntry.id] as key.
  Future<void> saveWeightEntry(WeightEntry entry) async {
    await _box.put(entry.id, entry);
  }

  /// Alias for [saveWeightEntry].
  Future<void> updateWeightEntry(WeightEntry entry) async {
    await saveWeightEntry(entry);
  }

  /// Deletes a specific weight entry by its [id].
  Future<void> deleteWeightEntry(String id) async {
    await _box.delete(id);
  }

  /// Retrieves weight entries recorded within the interval [startDate] through [endDate],
  /// sorted chronologically for chart display (fl_chart).
  List<WeightEntry> getEntriesForRange(
    DateTime startDate,
    DateTime endDate, {
    bool ascending = true,
  }) {
    final startOfRange = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfRange = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final filtered = _box.values.where((entry) {
      return !entry.date.isBefore(startOfRange) &&
          !entry.date.isAfter(endOfRange);
    }).toList();

    filtered.sort((a, b) =>
        ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    return filtered;
  }

  /// Computes the net weight change between the earliest and latest measurement.
  /// A negative value represents weight loss; a positive value represents gain.
  /// Returns null if fewer than 2 entries are available.
  double? calculateTotalWeightChange() {
    final entries = getAllWeightEntries(ascending: true);
    if (entries.length < 2) return null;

    final earliest = entries.first.weightKg;
    final latest = entries.last.weightKg;
    return latest - earliest;
  }

  /// Reactive stream yielding sorted weight entries whenever the box changes.
  Stream<List<WeightEntry>> watchWeightEntries({bool ascending = false}) async* {
    yield getAllWeightEntries(ascending: ascending);
    yield* _box.watch().map((_) => getAllWeightEntries(ascending: ascending));
  }

  /// Provides a [ValueListenable] for Flutter UI widgets.
  ValueListenable<Box<WeightEntry>> get weightListenable {
    return _box.listenable();
  }
}
