import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/water_repository.dart';
import 'diary_provider.dart';

/// Provider for [WaterRepository] dependency injection.
final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository();
});

/// StateNotifier that manages hydration tracking for a specific [dateKey] (YYYY-MM-DD).
class WaterNotifier extends StateNotifier<DailyWaterLog> {
  final WaterRepository _repository;
  final String dateKey;

  WaterNotifier(this._repository, this.dateKey)
      : super(_repository.getWaterLog(dateKey));

  /// Adds [amountMl] to the current day's intake.
  Future<void> addWater(int amountMl) async {
    final updated = await _repository.addWater(dateKey, amountMl);
    state = updated;
  }

  /// Removes [amountMl] from the current day's intake (clamped at 0).
  Future<void> removeWater(int amountMl) async {
    final updated = await _repository.removeWater(dateKey, amountMl);
    state = updated;
  }

  /// Explicitly sets the water consumption in milliliters.
  Future<void> setWater(int amountMl) async {
    final updated = await _repository.setWater(dateKey, amountMl);
    state = updated;
  }

  /// Resets daily water intake to 0 ml.
  Future<void> resetWater() async {
    final updated = await _repository.resetWater(dateKey);
    state = updated;
  }

  /// Refreshes water log from repository storage.
  void refresh() {
    state = _repository.getWaterLog(dateKey);
  }
}

/// Global provider that automatically stays in sync with the currently active diary date.
final waterProvider =
    StateNotifierProvider<WaterNotifier, DailyWaterLog>((ref) {
  final repo = ref.watch(waterRepositoryProvider);
  final dateKey = ref.watch(selectedDateKeyProvider);
  return WaterNotifier(repo, dateKey);
});

/// Family provider allowing hydration management for arbitrary date keys.
final waterFamilyProvider =
    StateNotifierProvider.family<WaterNotifier, DailyWaterLog, String>(
        (ref, dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return WaterNotifier(repo, dateKey);
});
