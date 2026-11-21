import 'package:hive/hive.dart';

/// Body circumferences recorded on one calendar date, in centimeters.
class BodyMeasurementsEntry {
  final DateTime date;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final double? hipsCm;
  final double? thighCm;

  const BodyMeasurementsEntry({
    required this.date,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.hipsCm,
    this.thighCm,
  });
}

class BodyMeasurementsEntryAdapter extends TypeAdapter<BodyMeasurementsEntry> {
  @override
  final int typeId = 6;

  @override
  BodyMeasurementsEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return BodyMeasurementsEntry(
      date: DateTime.parse(fields[0] as String),
      waistCm: (fields[1] as num?)?.toDouble(),
      chestCm: (fields[2] as num?)?.toDouble(),
      armCm: (fields[3] as num?)?.toDouble(),
      hipsCm: (fields[4] as num?)?.toDouble(),
      thighCm: (fields[5] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurementsEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date.toIso8601String())
      ..writeByte(1)
      ..write(obj.waistCm)
      ..writeByte(2)
      ..write(obj.chestCm)
      ..writeByte(3)
      ..write(obj.armCm)
      ..writeByte(4)
      ..write(obj.hipsCm)
      ..writeByte(5)
      ..write(obj.thighCm);
  }
}
