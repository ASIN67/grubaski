import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/user_repository.dart';
import '../utils/nutrition_calculator.dart';

/// Provider for [UserRepository] dependency injection.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// StateNotifier that manages user profile state, biometrics, nutrition calculations,
/// and onboarding completion status.
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final UserRepository _repository;

  UserProfileNotifier(this._repository) : super(_repository.getUserProfile());

  /// Refreshes user profile state from local Hive repository.
  Future<void> reloadProfile() async {
    state = _repository.getUserProfile();
  }

  /// Whether the user has an active, configured profile (completed onboarding).
  bool get isOnboardingCompleted => state != null;

  /// Creates and persists an initial [UserProfile] from onboarding inputs,
  /// automatically calculating nutrition targets via [NutritionCalculator].
  Future<UserProfile> createProfile({
    required Gender gender,
    required int age,
    required double startWeightKg,
    required double targetWeightKg,
    required double heightCm,
    required ActivityLevel activityLevel,
    WeightGoal? goal,
    double weeklyPaceKg = 0.5,
  }) async {
    final effectiveGoal = goal ??
        NutritionCalculator.deduceGoal(
          currentWeightKg: startWeightKg,
          targetWeightKg: targetWeightKg,
        );

    final targets = NutritionCalculator.calculate(
      gender: gender,
      age: age,
      weightKg: startWeightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
      goal: effectiveGoal,
      targetWeightKg: targetWeightKg,
      weeklyPaceKg: weeklyPaceKg,
    );

    final profile = UserProfile(
      gender: gender,
      age: age,
      startWeightKg: startWeightKg,
      targetWeightKg: targetWeightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
      goal: effectiveGoal,
      weeklyPaceKg: weeklyPaceKg,
      dailyCaloriesGoal: targets.dailyCalories,
      proteinGoalGrams: targets.proteinGrams,
      carbsGoalGrams: targets.carbsGrams,
      fatGoalGrams: targets.fatGrams,
      waterGoalMl: targets.waterGoalMl,
    );

    await _repository.saveUserProfile(profile);
    state = profile;
    return profile;
  }

  /// Updates user biometrics (e.g. weight, goal, activity level),
  /// recalculating nutritional targets when [recalculateGoals] is true.
  Future<void> updateBiometrics({
    Gender? gender,
    int? age,
    double? startWeightKg,
    double? targetWeightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    WeightGoal? goal,
    double? weeklyPaceKg,
    bool recalculateGoals = true,
  }) async {
    final current = state;
    if (current == null) return;

    final updatedGender = gender ?? current.gender;
    final updatedAge = age ?? current.age;
    final updatedStartWeight = startWeightKg ?? current.startWeightKg;
    final updatedTargetWeight = targetWeightKg ?? current.targetWeightKg;
    final updatedHeight = heightCm ?? current.heightCm;
    final updatedActivity = activityLevel ?? current.activityLevel;
    final updatedPace = weeklyPaceKg ?? current.weeklyPaceKg;
    final updatedGoal = goal ??
        NutritionCalculator.deduceGoal(
          currentWeightKg: updatedStartWeight,
          targetWeightKg: updatedTargetWeight,
        );

    final int dailyCalories;
    final int proteinGrams;
    final int carbsGrams;
    final int fatGrams;
    final int waterGoal;

    if (recalculateGoals) {
      final targets = NutritionCalculator.calculate(
        gender: updatedGender,
        age: updatedAge,
        weightKg: updatedStartWeight,
        heightCm: updatedHeight,
        activityLevel: updatedActivity,
        goal: updatedGoal,
        targetWeightKg: updatedTargetWeight,
        weeklyPaceKg: updatedPace,
      );
      dailyCalories = targets.dailyCalories;
      proteinGrams = targets.proteinGrams;
      carbsGrams = targets.carbsGrams;
      fatGrams = targets.fatGrams;
      waterGoal = targets.waterGoalMl;
    } else {
      dailyCalories = current.dailyCaloriesGoal;
      proteinGrams = current.proteinGoalGrams;
      carbsGrams = current.carbsGoalGrams;
      fatGrams = current.fatGoalGrams;
      waterGoal = current.waterGoalMl;
    }

    final updatedProfile = current.copyWith(
      gender: updatedGender,
      age: updatedAge,
      startWeightKg: updatedStartWeight,
      targetWeightKg: updatedTargetWeight,
      heightCm: updatedHeight,
      activityLevel: updatedActivity,
      goal: updatedGoal,
      weeklyPaceKg: updatedPace,
      dailyCaloriesGoal: dailyCalories,
      proteinGoalGrams: proteinGrams,
      carbsGoalGrams: carbsGrams,
      fatGoalGrams: fatGrams,
      waterGoalMl: waterGoal,
    );

    await _repository.saveUserProfile(updatedProfile);
    state = updatedProfile;
  }

  /// Manually overrides individual caloric or macronutrient goals.
  Future<void> updateNutritionalGoals({
    int? dailyCaloriesGoal,
    int? proteinGoalGrams,
    int? carbsGoalGrams,
    int? fatGoalGrams,
    int? waterGoalMl,
  }) async {
    final current = state;
    if (current == null) return;

    final updatedProfile = current.copyWith(
      dailyCaloriesGoal: dailyCaloriesGoal,
      proteinGoalGrams: proteinGoalGrams,
      carbsGoalGrams: carbsGoalGrams,
      fatGoalGrams: fatGoalGrams,
      waterGoalMl: waterGoalMl,
    );

    await _repository.saveUserProfile(updatedProfile);
    state = updatedProfile;
  }

  /// Saves any direct modifications to the profile.
  Future<void> saveProfile(UserProfile profile) async {
    await _repository.saveUserProfile(profile);
    state = profile;
  }

  /// Completely deletes user profile from local storage.
  Future<void> deleteProfile() async {
    await _repository.deleteUserProfile();
    state = null;
  }
}

/// Global provider for [UserProfileNotifier] state.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserProfileNotifier(repo);
});

/// Convenience provider returning whether onboarding is completed.
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile != null;
});
