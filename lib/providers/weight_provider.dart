import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/weight_repository.dart';

/// Provider for [WeightRepository] dependency injection.
final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository();
});

/// StateNotifier that manages body weight history, logs new measurements,
/// and computes chronological weight changes.
class WeightNotifier extends StateNotifier<List<WeightEntry>> {
  final WeightRepository _repository;

  WeightNotifier(this._repository)
      : super(_repository.getAllWeightEntries(ascending: false));

  /// Reloads all weight entries from storage (newest first).
  void refresh() {
    state = _repository.getAllWeightEntries(ascending: false);
  }

  /// Records a new weight measurement.
  /// If an entry exists on the same day, updates it to prevent duplicate weigh-ins.
  Future<WeightEntry> logWeight({
    required double weightKg,
    DateTime? date,
    bool updateExistingSameDay = true,
  }) async {
    final entry = await _repository.logWeight(
      weightKg: weightKg,
      date: date ?? DateTime.now(),
      updateExistingSameDay: updateExistingSameDay,
    );
    refresh();
    return entry;
  }

  /// Deletes a weight entry by its [id].
  Future<void> deleteEntry(String id) async {
    await _repository.deleteWeightEntry(id);
    refresh();
  }

  /// Calculates net weight change between earliest recorded entry and newest entry.
  /// Negative value denotes weight loss, positive value denotes weight gain.
  /// Returns null if fewer than 2 measurements exist.
  double? calculateTotalChange() {
    return _repository.calculateTotalWeightChange();
  }

  /// Returns the most recently logged [WeightEntry], or null if empty.
  WeightEntry? get latestEntry => state.isNotEmpty ? state.first : null;

  /// Returns the earliest recorded [WeightEntry], or null if empty.
  WeightEntry? get earliestEntry => state.isNotEmpty ? state.last : null;
}

/// Global provider for weight entry history (sorted newest first).
final weightProvider =
    StateNotifierProvider<WeightNotifier, List<WeightEntry>>((ref) {
  final repo = ref.watch(weightRepositoryProvider);
  return WeightNotifier(repo);
});

/// Provider for the most recent weight entry.
final latestWeightProvider = Provider<WeightEntry?>((ref) {
  final entries = ref.watch(weightProvider);
  return entries.isNotEmpty ? entries.first : null;
});

/// Provider for total weight change (kg).
final weightChangeProvider = Provider<double?>((ref) {
  final entries = ref.watch(weightProvider);
  if (entries.length < 2) return null;
  final newest = entries.first.weightKg;
  final oldest = entries.last.weightKg;
  return (newest - oldest);
});

/// Provider returning weight entries sorted chronologically (oldest first)
/// specifically tailored for line charts (fl_chart).
final weightChartEntriesProvider = Provider<List<WeightEntry>>((ref) {
  final entries = ref.watch(weightProvider);
  final sorted = List<WeightEntry>.from(entries)
    ..sort((a, b) => a.date.compareTo(b.date));
  return sorted;
});
