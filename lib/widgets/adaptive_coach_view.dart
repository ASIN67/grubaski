import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/weight_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';

class AdaptiveCoachView extends ConsumerStatefulWidget {
  const AdaptiveCoachView({super.key});

  @override
  ConsumerState<AdaptiveCoachView> createState() => _AdaptiveCoachViewState();
}

class _AdaptiveCoachViewState extends ConsumerState<AdaptiveCoachView> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profile = ref.watch(userProfileProvider);
    final weightEntries = ref.watch(weightProvider);
    final diaryRepo = ref.watch(diaryRepositoryProvider);

    if (profile == null) {
      return const Center(child: Text('Skonfiguruj najpierw swój profil.'));
    }

    // Gather weight entries from the past 14 days
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final recentWeights = weightEntries
        .where((w) => today.difference(DateUtils.dateOnly(w.date)).inDays <= 14)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Compute average intake over the past 7-14 days
    double totalCalories = 0;
    int daysWithData = 0;
    for (int i = 0; i < 14; i++) {
      final d = now.subtract(Duration(days: i));
      final k = DateFormatter.toDateKey(d);
      final entries = diaryRepo.getEntriesForDateKey(k);
      if (entries.isNotEmpty) {
        final sum = entries.fold<double>(0, (prev, e) => prev + e.calories);
        totalCalories += sum;
        daysWithData++;
      }
    }

    final double avgDailyIntake = daysWithData > 0
        ? (totalCalories / daysWithData)
        : profile.dailyCaloriesGoal.toDouble();

    // Analyze weight changes (require at least 5 calendar days span to avoid water-weight distortion)
    double weightDelta = 0.0;
    int daysBetweenWeights = 0;
    bool hasEnoughWeightData = false;

    if (recentWeights.length >= 2) {
      // recentWeights is sorted newest first
      final newest = recentWeights.first;
      final oldest = recentWeights.last;
      daysBetweenWeights = DateUtils.dateOnly(newest.date)
          .difference(DateUtils.dateOnly(oldest.date))
          .inDays;
      if (daysBetweenWeights >= 5) {
        hasEnoughWeightData = true;
        weightDelta = newest.weightKg - oldest.weightKg;
      }
    }

    // Expenditure (TDEE) calculation
    // Delta kg * 7700 kcal / days = caloric balance
    final double dailyCaloricSurplusOrDeficit = hasEnoughWeightData
        ? (weightDelta * 7700.0) / daysBetweenWeights
        : 0.0;

    // True TDEE = Intake - Balance
    double calculatedTdee = avgDailyIntake - dailyCaloricSurplusOrDeficit;
    if (calculatedTdee < 1200) calculatedTdee = 1800;
    if (calculatedTdee > 4500) calculatedTdee = 3200;

    // Weekly weight pace (kg/week)
    final double weeklyPace =
        hasEnoughWeightData ? (weightDelta / daysBetweenWeights) * 7.0 : 0.0;

    // Recommendation logic based on user goal
    int recommendedKcal = profile.dailyCaloriesGoal;
    String adviceExplanation = '';

    if (!hasEnoughWeightData) {
      adviceExplanation =
          'Potrzeba min. 5 dni pomiarów wagi, aby wiarygodnie wyliczyć tempo i skorygować kalorie.';
    } else {
      switch (profile.goal) {
        case WeightGoal.reduction:
          // Target loss pace: 0.5 kg/week => ~550 kcal deficit
          final targetDeficit = (profile.weeklyPaceKg * 1100.0).clamp(300.0, 900.0);
          recommendedKcal = (calculatedTdee - targetDeficit).round();
          if (weeklyPace < -0.9) {
            adviceExplanation =
                'Chudniesz bardzo szybko (${weeklyPace.toStringAsFixed(2)} kg/tydz.). Zwiększamy kalorie, aby chronić Twoją masę mięśniową i energię.';
          } else if (weeklyPace > -0.2) {
            adviceExplanation =
                'Tempo redukcji (${weeklyPace.toStringAsFixed(2)} kg/tydz.) zwolniło. Sugerujemy lekkie obniżenie kalorii, aby powrócić do planowanego spadku wagi.';
          } else {
            adviceExplanation =
                'Świetne tempo redukcji (${weeklyPace.toStringAsFixed(2)} kg/tydz.)! Twój metabolizm pracuje stabilnie.';
          }
        case WeightGoal.surplus:
          // Target surplus: ~250-350 kcal
          recommendedKcal = (calculatedTdee + 300).round();
          if (weeklyPace > 0.5) {
            adviceExplanation =
                'Waga rośnie nieco za szybko (+${weeklyPace.toStringAsFixed(2)} kg/tydz.). Korygujemy nadwyżkę, by budować czystą masę mięśniową zamiast tkanki tłuszczowej.';
          } else if (weeklyPace < 0.1) {
            adviceExplanation =
                'Waga stoi w miejscu. Zwiększamy kalorie, aby stymulować przyrost masy i progres siłowy.';
          } else {
            adviceExplanation =
                'Optymalne tempo budowy masy (+${weeklyPace.toStringAsFixed(2)} kg/tydz.)!';
          }
        case WeightGoal.maintenance:
          recommendedKcal = calculatedTdee.round();
          adviceExplanation =
              'Utrzymanie wagi: Twój wyliczony wydatek energetyczny idealnie równoważy wagę.';
      }

      recommendedKcal = recommendedKcal.clamp(1200, 4500);
    }
    final int calorieDelta = recommendedKcal - profile.dailyCaloriesGoal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Hero Coach Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF047857).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adaptacyjny Coach Kalorii',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Algorytm Dynamicznego TDEE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      profile.goal.displayName.split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Twój rzeczywisty metabolizm (TDEE):',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    '${calculatedTdee.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'kcal / dzień',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Key stats tiles
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Średnie spożycie',
                value: '${avgDailyIntake.round()} kcal',
                subtitle: 'z ostatnich 14 dni',
                color: AppColors.primaryGreen,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Tempo wagi',
                value: hasEnoughWeightData
                    ? '${weeklyPace > 0 ? '+' : ''}${weeklyPace.toStringAsFixed(2)} kg'
                    : 'Brak danych',
                subtitle: 'na tydzień',
                color: weeklyPace <= 0 ? AppColors.proteinBlue : AppColors.carbsAmber,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recommendation Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: AppColors.carbsAmber, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zalecenie na kolejny tydzień',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  adviceExplanation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sugerowany dzienny cel:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$recommendedKcal kcal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (calorieDelta >= 0 ? Colors.green : Colors.orange).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          calorieDelta == 0
                              ? 'Bez zmian'
                              : '${calorieDelta > 0 ? '+' : ''}$calorieDelta kcal',
                          style: TextStyle(
                            color: calorieDelta >= 0 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Apply Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: _isApplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isApplying
                        ? 'Zapisywanie...'
                        : 'Zastosuj zalecany cel ($recommendedKcal kcal)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _isApplying || calorieDelta == 0
                      ? null
                      : () async {
                          setState(() => _isApplying = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(userProfileProvider.notifier)
                                .applyRecommendedCalorieTarget(recommendedKcal);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.primaryGreenDark,
                                  content: Text(
                                    'Zaktualizowano dzienny cel kalorii do $recommendedKcal kcal!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text('Błąd zapisu profilu: $e'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isApplying = false);
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // How it works card
        Card(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jak działa Adaptacyjny Coach?',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Zamiast zgadywać z kalkulatorów internetowych, algorytm mierzy Twój prawdziwy metabolizm. Jeśli chudniesz szybciej lub wolniej niż planowane tempo, Coach automatycznie koryguje zapotrzebowanie.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
