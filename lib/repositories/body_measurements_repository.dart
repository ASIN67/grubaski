import 'package:hive/hive.dart';

import '../models/body_measurements_entry.dart';
import '../services/hive_service.dart';
import '../utils/date_formatter.dart';

class BodyMeasurementsRepository {
  final HiveService _hiveService;

  BodyMeasurementsRepository({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService.instance;

  Box<BodyMeasurementsEntry> get _box =>
      _hiveService.bodyMeasurementsEntriesBox;

  List<BodyMeasurementsEntry> getEntries() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Updates only the circumferences supplied for the selected calendar date.
  Future<void> save(BodyMeasurementsEntry entry) {
    final key = DateFormatter.toDateKey(entry.date);
    final existing = _box.get(key);

    return _box.put(
      key,
      BodyMeasurementsEntry(
        date: DateFormatter.fromDateKey(key),
        waistCm: entry.waistCm ?? existing?.waistCm,
        chestCm: entry.chestCm ?? existing?.chestCm,
        armCm: entry.armCm ?? existing?.armCm,
        hipsCm: entry.hipsCm ?? existing?.hipsCm,
        thighCm: entry.thighCm ?? existing?.thighCm,
      ),
    );
  }
}
