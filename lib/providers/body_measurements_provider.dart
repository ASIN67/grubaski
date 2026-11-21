import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_measurements_entry.dart';
import '../repositories/body_measurements_repository.dart';

final bodyMeasurementsRepositoryProvider = Provider<BodyMeasurementsRepository>(
  (ref) => BodyMeasurementsRepository(),
);

final bodyMeasurementsProvider = StateNotifierProvider.autoDispose<
    BodyMeasurementsNotifier, List<BodyMeasurementsEntry>>((ref) {
  return BodyMeasurementsNotifier(
      ref.watch(bodyMeasurementsRepositoryProvider));
});

class BodyMeasurementsNotifier
    extends StateNotifier<List<BodyMeasurementsEntry>> {
  final BodyMeasurementsRepository _repository;

  BodyMeasurementsNotifier(this._repository) : super(_repository.getEntries());

  Future<void> save(BodyMeasurementsEntry entry) async {
    await _repository.save(entry);
    if (mounted) refresh();
  }

  void refresh() {
    state = _repository.getEntries();
  }
}
