import 'package:hive/hive.dart';

/// User gender enum.
enum Gender {
  male,
  female;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Mężczyzna';
      case Gender.female:
        return 'Kobieta';
    }
  }
}

/// Physical activity level used for TDEE computation.
enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Siedzący (brak ćwiczeń, praca biurowa)';
      case ActivityLevel.light:
        return 'Niska aktywność (trening 1-2 razy w tyg.)';
      case ActivityLevel.moderate:
        return 'Umiarkowana (trening 3-5 razy w tyg.)';
      case ActivityLevel.active:
        return 'Duża aktywność (codzienne intensywne treningi)';
      case ActivityLevel.veryActive:
        return 'Bardzo duża (sportowiec, praca fizyczna)';
    }
  }

  /// Activity coefficient for TDEE (Total Daily Energy Expenditure).
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }
}

/// Dietary and body weight goal.
enum WeightGoal {
  reduction,
  maintenance,
  surplus;

  String get displayName {
    switch (this) {
      case WeightGoal.reduction:
        return 'Redukcja wagi (-400 kcal)';
      case WeightGoal.maintenance:
        return 'Utrzymanie wagi (0 kcal)';
      case WeightGoal.surplus:
        return 'Masa / Budowa mięśni (+300 kcal)';
    }
  }

  /// Calorie offset relative to TDEE.
  int get calorieOffset {
    switch (this) {
      case WeightGoal.reduction:
        return -400;
      case WeightGoal.maintenance:
        return 0;
      case WeightGoal.surplus:
        return 300;
    }
  }
}

/// Model storing user biometric data and calculated nutritional targets.
/// Hive TypeId: 0.
class UserProfile {
  final Gender gender;
  final int age;
  final double startWeightKg;
  final double targetWeightKg;
  final double heightCm;
  final ActivityLevel activityLevel;
  final WeightGoal goal;
  final double weeklyPaceKg;
  final int dailyCaloriesGoal;
  final int proteinGoalGrams;
  final int carbsGoalGrams;
  final int fatGoalGrams;
  final int waterGoalMl;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.startWeightKg,
    required this.targetWeightKg,
    required this.heightCm,
    required this.activityLevel,
    required this.goal,
    this.weeklyPaceKg = 0.5,
    required this.dailyCaloriesGoal,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    required this.waterGoalMl,
  });

  /// Creates a copy of [UserProfile] with optionally replaced fields.
  UserProfile copyWith({
    Gender? gender,
    int? age,
    double? startWeightKg,
    double? targetWeightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    WeightGoal? goal,
    double? weeklyPaceKg,
    int? dailyCaloriesGoal,
    int? proteinGoalGrams,
    int? carbsGoalGrams,
    int? fatGoalGrams,
    int? waterGoalMl,
  }) {
    return UserProfile(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      startWeightKg: startWeightKg ?? this.startWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      weeklyPaceKg: weeklyPaceKg ?? this.weeklyPaceKg,
      dailyCaloriesGoal: dailyCaloriesGoal ?? this.dailyCaloriesGoal,
      proteinGoalGrams: proteinGoalGrams ?? this.proteinGoalGrams,
      carbsGoalGrams: carbsGoalGrams ?? this.carbsGoalGrams,
      fatGoalGrams: fatGoalGrams ?? this.fatGoalGrams,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          gender == other.gender &&
          age == other.age &&
          startWeightKg == other.startWeightKg &&
          targetWeightKg == other.targetWeightKg &&
          heightCm == other.heightCm &&
          activityLevel == other.activityLevel &&
          goal == other.goal &&
          weeklyPaceKg == other.weeklyPaceKg &&
          dailyCaloriesGoal == other.dailyCaloriesGoal &&
          proteinGoalGrams == other.proteinGoalGrams &&
          carbsGoalGrams == other.carbsGoalGrams &&
          fatGoalGrams == other.fatGoalGrams &&
          waterGoalMl == other.waterGoalMl;

  @override
  int get hashCode =>
      gender.hashCode ^
      age.hashCode ^
      startWeightKg.hashCode ^
      targetWeightKg.hashCode ^
      heightCm.hashCode ^
      activityLevel.hashCode ^
      goal.hashCode ^
      weeklyPaceKg.hashCode ^
      dailyCaloriesGoal.hashCode ^
      proteinGoalGrams.hashCode ^
      carbsGoalGrams.hashCode ^
      fatGoalGrams.hashCode ^
      waterGoalMl.hashCode;
}

/// Manual Hive TypeAdapter for [UserProfile] with TypeId 0.
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return UserProfile(
      gender: Gender.values.firstWhere(
        (e) => e.name == (fields[0] as String?),
        orElse: () => Gender.male,
      ),
      age: fields[1] as int,
      startWeightKg: (fields[2] as num).toDouble(),
      targetWeightKg: (fields[3] as num).toDouble(),
      heightCm: (fields[4] as num).toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == (fields[5] as String?),
        orElse: () => ActivityLevel.sedentary,
      ),
      goal: WeightGoal.values.firstWhere(
        (e) => e.name == (fields[6] as String?),
        orElse: () => WeightGoal.maintenance,
      ),
      dailyCaloriesGoal: fields[7] as int,
      proteinGoalGrams: fields[8] as int,
      carbsGoalGrams: fields[9] as int,
      fatGoalGrams: fields[10] as int,
      waterGoalMl: fields[11] as int,
      weeklyPaceKg: (fields[12] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(13) // Total number of fields
      ..writeByte(0)
      ..write(obj.gender.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.startWeightKg)
      ..writeByte(3)
      ..write(obj.targetWeightKg)
      ..writeByte(4)
      ..write(obj.heightCm)
      ..writeByte(5)
      ..write(obj.activityLevel.name)
      ..writeByte(6)
      ..write(obj.goal.name)
      ..writeByte(7)
      ..write(obj.dailyCaloriesGoal)
      ..writeByte(8)
      ..write(obj.proteinGoalGrams)
      ..writeByte(9)
      ..write(obj.carbsGoalGrams)
      ..writeByte(10)
      ..write(obj.fatGoalGrams)
      ..writeByte(11)
      ..write(obj.waterGoalMl)
      ..writeByte(12)
      ..write(obj.weeklyPaceKg);
  }
}
