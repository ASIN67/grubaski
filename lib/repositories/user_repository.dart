import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../services/hive_service.dart';

/// Repository responsible for persisting and managing user biometrics,
/// dietary goals, and profile settings in local Hive storage.
class UserRepository {
  final HiveService _hiveService;

  static const String _userProfileKey = 'current_user_profile';

  UserRepository({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService.instance;

  Box<UserProfile> get _box => _hiveService.userProfileBox;

  /// Synchronously retrieves the current user profile, or null if not yet created.
  UserProfile? getUserProfile() {
    return _box.get(_userProfileKey);
  }

  /// Asynchronously retrieves the current user profile.
  Future<UserProfile?> getProfile() async {
    return getUserProfile();
  }

  /// Indicates whether the user has completed onboarding and has an active profile.
  bool get hasProfile {
    return _box.containsKey(_userProfileKey) && _box.get(_userProfileKey) != null;
  }

  /// Persists or updates the complete user profile.
  Future<void> saveUserProfile(UserProfile profile) async {
    await _box.put(_userProfileKey, profile);
  }

  /// Alias for [saveUserProfile].
  Future<void> updateUserProfile(UserProfile profile) async {
    await saveUserProfile(profile);
  }

  /// Updates specific nutritional target goals for the existing profile.
  /// If no profile exists, this operation is a no-op.
  Future<UserProfile?> updateNutritionalGoals({
    int? dailyCaloriesGoal,
    int? proteinGoalGrams,
    int? carbsGoalGrams,
    int? fatGoalGrams,
    int? waterGoalMl,
  }) async {
    final current = getUserProfile();
    if (current == null) return null;

    final updated = current.copyWith(
      dailyCaloriesGoal: dailyCaloriesGoal,
      proteinGoalGrams: proteinGoalGrams,
      carbsGoalGrams: carbsGoalGrams,
      fatGoalGrams: fatGoalGrams,
      waterGoalMl: waterGoalMl,
    );

    await saveUserProfile(updated);
    return updated;
  }

  /// Updates biometric parameters (e.g., after a new weigh-in or changing goal)
  /// and persists the updated profile.
  Future<UserProfile?> updateBiometrics({
    double? startWeightKg,
    double? targetWeightKg,
    double? heightCm,
    int? age,
    ActivityLevel? activityLevel,
    WeightGoal? goal,
  }) async {
    final current = getUserProfile();
    if (current == null) return null;

    final updated = current.copyWith(
      startWeightKg: startWeightKg,
      targetWeightKg: targetWeightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
      goal: goal,
    );

    await saveUserProfile(updated);
    return updated;
  }

  /// Deletes the user profile from local storage (e.g. during account reset).
  Future<void> deleteUserProfile() async {
    await _box.delete(_userProfileKey);
  }

  /// Reactive stream that emits the current [UserProfile] immediately,
  /// and re-emits whenever the profile changes in Hive.
  Stream<UserProfile?> watchUserProfile() async* {
    yield getUserProfile();
    yield* _box.watch(key: _userProfileKey).map((event) {
      if (event.deleted) {
        return null;
      }
      return event.value as UserProfile?;
    });
  }

  /// Provides a [ValueListenable] for Flutter UI widgets (e.g. ValueListenableBuilder).
  ValueListenable<Box<UserProfile>> get profileListenable {
    return _box.listenable(keys: [_userProfileKey]);
  }
}
