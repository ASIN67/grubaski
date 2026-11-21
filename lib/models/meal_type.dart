import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Enum representing the 5 standard daily meal categories.
/// Registered with Hive TypeId: 2.
enum MealType {
  breakfast,
  secondBreakfast,
  lunch,
  snacks,
  dinner;

  /// User-friendly Polish label for UI display.
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Śniadanie';
      case MealType.secondBreakfast:
        return 'II Śniadanie';
      case MealType.lunch:
        return 'Obiad';
      case MealType.snacks:
        return 'Przekąski';
      case MealType.dinner:
        return 'Kolacja';
    }
  }

  /// Default icon associated with the meal.
  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny_rounded;
      case MealType.secondBreakfast:
        return Icons.local_cafe_rounded;
      case MealType.lunch:
        return Icons.restaurant_rounded;
      case MealType.snacks:
        return Icons.cookie_rounded;
      case MealType.dinner:
        return Icons.nights_stay_rounded;
    }
  }
}

/// Manual Hive TypeAdapter for [MealType].
/// Eliminates the need for build_runner code generation.
class MealTypeAdapter extends TypeAdapter<MealType> {
  @override
  final int typeId = 2;

  @override
  MealType read(BinaryReader reader) {
    final byte = reader.readByte();
    if (byte >= 0 && byte < MealType.values.length) {
      return MealType.values[byte];
    }
    return MealType.breakfast;
  }

  @override
  void write(BinaryWriter writer, MealType obj) {
    writer.writeByte(obj.index);
  }
}
