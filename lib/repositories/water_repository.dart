import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import '../utils/date_formatter.dart';

/// Repository managing daily water consumption tracking and statistics.
class WaterRepository {
  final HiveService _hiveService;

  WaterRepository({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService.instance;

  Box<DailyWaterLog> get _box => _hiveService.waterLogsBox;

  /// Retrieves the water log for a given [dateKey] (YYYY-MM-DD).
  /// If no log exists for this date, returns a [DailyWaterLog] with 0 ml.
  DailyWaterLog getWaterLog(String dateKey) {
    return _box.get(dateKey) ?? DailyWaterLog(dateKey: dateKey, amountMl: 0);
  }

  /// Retrieves the water log for a given [DateTime].
  DailyWaterLog getWaterLogForDate(DateTime date) {
    return getWaterLog(DateFormatter.toDateKey(date));
  }

  /// Returns the logged water amount in milliliters for [dateKey].
  int getWaterAmount(String dateKey) {
    return getWaterLog(dateKey).amountMl;
  }

  /// Persists a [DailyWaterLog] into local storage using [DailyWaterLog.dateKey] as key.
  Future<DailyWaterLog> saveWaterLog(DailyWaterLog log) async {
    await _box.put(log.dateKey, log);
    return log;
  }

  /// Explicitly sets the total water intake in milliliters for a given [dateKey].
  /// Clamps negative values to 0.
  Future<DailyWaterLog> setWater(String dateKey, int amountMl) async {
    final sanitizedAmount = amountMl < 0 ? 0 : amountMl;
    final log = DailyWaterLog(dateKey: dateKey, amountMl: sanitizedAmount);
    return saveWaterLog(log);
  }

  /// Adds [amountMl] (e.g. 250 ml for a glass of water) to the day's intake.
  Future<DailyWaterLog> addWater(String dateKey, int amountMl) async {
    if (amountMl <= 0) return getWaterLog(dateKey);
    final current = getWaterLog(dateKey);
    final updatedAmount = current.amountMl + amountMl;
    return setWater(dateKey, updatedAmount);
  }

  /// Deducts [amountMl] from the day's intake, clamping at a minimum of 0 ml.
  Future<DailyWaterLog> removeWater(String dateKey, int amountMl) async {
    if (amountMl <= 0) return getWaterLog(dateKey);
    final current = getWaterLog(dateKey);
    final updatedAmount = (current.amountMl - amountMl).clamp(0, 99999);
    return setWater(dateKey, updatedAmount);
  }

  /// Resets water consumption for [dateKey] back to 0 ml.
  Future<DailyWaterLog> resetWater(String dateKey) async {
    return setWater(dateKey, 0);
  }

  /// Retrieves historical water intake for a range of dates [startDate] through [endDate].
  /// Missing days default to 0 ml. Useful for weekly or monthly charts.
  Map<String, int> getWaterLogsForRange(DateTime startDate, DateTime endDate) {
    final result = <String, int>{};
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      final key = DateFormatter.toDateKey(current);
      result[key] = getWaterAmount(key);
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Reactive stream yielding the water log for [dateKey] on initial subscription
  /// and whenever the box is updated.
  Stream<DailyWaterLog> watchWaterLog(String dateKey) async* {
    yield getWaterLog(dateKey);
    yield* _box.watch(key: dateKey).map((event) {
      if (event.deleted || event.value == null) {
        return DailyWaterLog(dateKey: dateKey, amountMl: 0);
      }
      return event.value as DailyWaterLog;
    });
  }

  /// Provides a [ValueListenable] for Flutter UI widgets.
  ValueListenable<Box<DailyWaterLog>> get waterListenable {
    return _box.listenable();
  }
}
