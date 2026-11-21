import 'package:hive/hive.dart';

/// Tracks the total water volume consumed on a given day in milliliters.
/// Hive TypeId: 4.
class DailyWaterLog {
  /// Format: 'YYYY-MM-DD', serves as unique key in the water box.
  final String dateKey;
  final int amountMl;

  const DailyWaterLog({
    required this.dateKey,
    required this.amountMl,
  });

  DailyWaterLog copyWith({
    String? dateKey,
    int? amountMl,
  }) {
    return DailyWaterLog(
      dateKey: dateKey ?? this.dateKey,
      amountMl: amountMl ?? this.amountMl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyWaterLog &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey &&
          amountMl == other.amountMl;

  @override
  int get hashCode => dateKey.hashCode ^ amountMl.hashCode;
}

/// Manual Hive TypeAdapter for [DailyWaterLog] with TypeId 4.
class DailyWaterLogAdapter extends TypeAdapter<DailyWaterLog> {
  @override
  final int typeId = 4;

  @override
  DailyWaterLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return DailyWaterLog(
      dateKey: fields[0] as String,
      amountMl: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyWaterLog obj) {
    writer
      ..writeByte(2) // Total number of fields
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.amountMl);
  }
}
