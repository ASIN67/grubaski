import 'package:hive/hive.dart';

/// Historical body weight measurement entry.
/// Hive TypeId: 5.
class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Manual Hive TypeAdapter for [WeightEntry] with TypeId 5.
class WeightEntryAdapter extends TypeAdapter<WeightEntry> {
  @override
  final int typeId = 5;

  @override
  WeightEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return WeightEntry(
      id: fields[0] as String,
      date: DateTime.parse(fields[1] as String),
      weightKg: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WeightEntry obj) {
    writer
      ..writeByte(3) // Total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date.toIso8601String())
      ..writeByte(2)
      ..write(obj.weightKg);
  }
}
