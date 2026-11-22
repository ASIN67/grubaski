import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/gamification_service.dart';
import 'diary_provider.dart';
import 'user_profile_provider.dart';
import 'water_provider.dart';
import 'weight_provider.dart';

/// Provider exposing the singleton [GamificationService].
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService.instance;
});

/// Reactive provider calculating the user's current and best habit streak.
final streakProvider = Provider<StreakInfo>((ref) {
  // Watch dependencies so streak updates reactively when meals or profile change
  ref.watch(diaryProvider);
  final profile = ref.watch(userProfileProvider);
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final service = ref.watch(gamificationServiceProvider);

  return service.calculateStreak(
    diaryRepo: diaryRepo,
    profile: profile,
  );
});

/// Reactive provider generating MacroFactor-style dynamic weight forecast.
final weightForecastProvider = Provider<WeightForecast>((ref) {
  // Watch profile, weight entries, and diary changes
  final profile = ref.watch(userProfileProvider);
  ref.watch(weightProvider);
  ref.watch(diaryProvider);

  final weightRepo = ref.watch(weightRepositoryProvider);
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final service = ref.watch(gamificationServiceProvider);

  return service.calculateForecast(
    profile: profile,
    weightRepo: weightRepo,
    diaryRepo: diaryRepo,
  );
});

/// Reactive provider evaluating all milestone badges and achievements.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  ref.watch(diaryProvider);
  ref.watch(waterProvider);
  ref.watch(weightProvider);
  final profile = ref.watch(userProfileProvider);
  final streak = ref.watch(streakProvider);

  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final waterRepo = ref.watch(waterRepositoryProvider);
  final weightRepo = ref.watch(weightRepositoryProvider);
  final service = ref.watch(gamificationServiceProvider);

  return service.evaluateAchievements(
    diaryRepo: diaryRepo,
    waterRepo: waterRepo,
    weightRepo: weightRepo,
    profile: profile,
    streakInfo: streak,
  );
});

/// Computes the ratio of unlocked achievements (e.g. 5 of 14).
final achievementsProgressProvider = Provider<({int unlocked, int total})>((ref) {
  final list = ref.watch(achievementsProvider);
  final unlocked = list.where((a) => a.isUnlocked).length;
  return (unlocked: unlocked, total: list.length);
});
