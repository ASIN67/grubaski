import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/user_profile_provider.dart';
import '../providers/weight_provider.dart';
import '../utils/app_colors.dart';
import '../utils/nutrition_calculator.dart';
import 'main_navigation_screen.dart';

/// Multi-step onboarding wizard for first-time users.
/// Captures gender, age, weight, target weight, height, activity level, and goal,
/// providing real-time calculation of BMR, TDEE, Calories, Protein, Carbs, Fat, and Water.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Onboarding Biometric State
  Gender _gender = Gender.male;
  int _age = 28;
  double _weightKg = 75.0;
  double _targetWeightKg = 70.0;
  double _heightCm = 175.0;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  double _weeklyPaceKg = 0.5;

  bool _isSaving = false;

  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: _age.toString());
    _weightController =
        TextEditingController(text: _weightKg.toStringAsFixed(1));
    _targetWeightController =
        TextEditingController(text: _targetWeightKg.toStringAsFixed(1));
    _heightController =
        TextEditingController(text: _heightCm.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  WeightGoal get _deducedGoal => NutritionCalculator.deduceGoal(
        currentWeightKg: _weightKg,
        targetWeightKg: _targetWeightKg,
      );

  NutritionCalculationResult get _calculatedPlan {
    return NutritionCalculator.calculate(
      gender: _gender,
      age: _age,
      weightKg: _weightKg,
      heightCm: _heightCm,
      activityLevel: _activityLevel,
      targetWeightKg: _targetWeightKg,
      weeklyPaceKg: _weeklyPaceKg,
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSaving = true);

    try {
      // 1. Create and save profile
      await ref.read(userProfileProvider.notifier).createProfile(
            gender: _gender,
            age: _age,
            startWeightKg: _weightKg,
            targetWeightKg: _targetWeightKg,
            heightCm: _heightCm,
            activityLevel: _activityLevel,
            goal: _deducedGoal,
            weeklyPaceKg: _weeklyPaceKg,
          );

      // 2. Log initial weigh-in
      await ref.read(weightProvider.notifier).logWeight(
            weightKg: _weightKg,
            date: DateTime.now(),
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać profilu.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plan = _calculatedPlan;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar & Back Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _previousStep,
                      splashRadius: 20,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Krok ${_currentStep + 1} z $_totalSteps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / _totalSteps,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balancing spacer
                ],
              ),
            ),

            // Main PageView content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentStep = idx);
                },
                children: [
                  _buildStepGenderAndAge(isDark),
                  _buildStepMeasurements(isDark),
                  _buildStepActivity(isDark),
                  _buildStepWeeklyPace(isDark, plan),
                  _buildStepSummary(isDark, plan),
                ],
              ),
            ),

            // Bottom Navigation Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : (_currentStep == _totalSteps - 1
                          ? _finishOnboarding
                          : _nextStep),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Zapisz i rozpocznij'
                              : 'Dalej',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Płeć i wiek
  Widget _buildStepGenderAndAge(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Witaj w Grubasku!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Skonfigurujmy Twój profil, aby precyzyjnie wyliczyć zapotrzebowanie kaloryczne.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Wybierz płeć',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSelectCard(
                title: 'Mężczyzna',
                icon: Icons.male_rounded,
                isSelected: _gender == Gender.male,
                isDark: isDark,
                onTap: () => setState(() => _gender = Gender.male),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSelectCard(
                title: 'Kobieta',
                icon: Icons.female_rounded,
                isSelected: _gender == Gender.female,
                isDark: isDark,
                onTap: () => setState(() => _gender = Gender.female),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Twój wiek',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_age lat',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _age.toDouble(),
          min: 14,
          max: 90,
          divisions: 76,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() {
              _age = val.round();
              _ageController.text = _age.toString();
            });
          },
        ),
      ],
    );
  }

  // STEP 2: Wymiary ciała
  Widget _buildStepMeasurements(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Wymiary ciała',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Podaj swój wzrost oraz obecną i docelową masę ciała.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // Wzrost
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Wzrost (cm)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_heightCm.toInt()} cm',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: _heightCm,
          min: 130,
          max: 220,
          divisions: 90,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() => _heightCm = val.roundToDouble());
          },
        ),

        const SizedBox(height: 20),

        // Aktualna waga
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktualna waga (kg)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_weightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: _weightKg,
          min: 40,
          max: 180,
          divisions: 280,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() => _weightKg = (val * 10).round() / 10.0);
          },
        ),

        const SizedBox(height: 20),

        // Docelowa waga
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Waga docelowa (kg)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_targetWeightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: _targetWeightKg,
          min: 40,
          max: 180,
          divisions: 280,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() {
              _targetWeightKg = (val * 10).round() / 10.0;
              // Reset default pace based on goal direction
              final g = _deducedGoal;
              if (g == WeightGoal.maintenance) {
                _weeklyPaceKg = 0.0;
              } else if (g == WeightGoal.surplus && _weeklyPaceKg > 0.5) {
                _weeklyPaceKg = 0.35;
              } else if (g == WeightGoal.reduction && _weeklyPaceKg == 0.0) {
                _weeklyPaceKg = 0.5;
              }
            });
          },
        ),

        const SizedBox(height: 12),

        // Real-time Deduced Goal Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _weightKg > _targetWeightKg + 0.2
                      ? Icons.trending_down_rounded
                      : (_weightKg < _targetWeightKg - 0.2
                          ? Icons.trending_up_rounded
                          : Icons.check_circle_outline_rounded),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Automatycznie dobrany cel:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _weightKg > _targetWeightKg + 0.2
                          ? 'Redukcja wagi (-${(_weightKg - _targetWeightKg).toStringAsFixed(1)} kg)'
                          : (_weightKg < _targetWeightKg - 0.2
                              ? 'Budowanie masy (+${(_targetWeightKg - _weightKg).toStringAsFixed(1)} kg)'
                              : 'Utrzymanie obecnej wagi'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Aktywność fizyczna
  Widget _buildStepActivity(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Poziom aktywności',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Wybierz poziom odpowiadający Twojemu codziennemu trybowi życia.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...ActivityLevel.values.map((level) {
          final isSelected = _activityLevel == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              onTap: () => setState(() => _activityLevel = level),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        level.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 4: Tempo na tydzień
  Widget _buildStepWeeklyPace(bool isDark, NutritionCalculationResult plan) {
    final goal = _deducedGoal;
    final diff = (_weightKg - _targetWeightKg).abs();

    // Define options according to goal
    final List<Map<String, dynamic>> paceOptions;
    if (goal == WeightGoal.reduction) {
      paceOptions = [
        {
          'pace': 0.25,
          'title': '0.25 kg / tydzień',
          'subtitle': 'Łagodne • deficyt ok. -275 kcal/dzień',
          'tag': 'Łatwe do utrzymania',
        },
        {
          'pace': 0.50,
          'title': '0.50 kg / tydzień',
          'subtitle': 'Zalecane • deficyt ok. -550 kcal/dzień',
          'tag': 'Optymalne i zdrowe',
        },
        {
          'pace': 0.75,
          'title': '0.75 kg / tydzień',
          'subtitle': 'Dynamiczne • deficyt ok. -825 kcal/dzień',
          'tag': 'Szybkie efekty',
        },
        {
          'pace': 1.00,
          'title': '1.00 kg / tydzień',
          'subtitle': 'Agresywne • deficyt ok. -1100 kcal/dzień',
          'tag': 'Wymaga dużej dyscypliny',
        },
      ];
    } else if (goal == WeightGoal.surplus) {
      paceOptions = [
        {
          'pace': 0.20,
          'title': '0.20 kg / tydzień',
          'subtitle': 'Czysta masa • nadwyżka ok. +220 kcal/dzień',
          'tag': 'Minimalny przyrost tłuszczu',
        },
        {
          'pace': 0.35,
          'title': '0.35 kg / tydzień',
          'subtitle': 'Zalecane • nadwyżka ok. +385 kcal/dzień',
          'tag': 'Zrównoważony wzrost siły',
        },
        {
          'pace': 0.50,
          'title': '0.50 kg / tydzień',
          'subtitle': 'Szybka masa • nadwyżka ok. +550 kcal/dzień',
          'tag': 'Dynamiczny przyrost wagi',
        },
      ];
    } else {
      paceOptions = [
        {
          'pace': 0.00,
          'title': 'Utrzymanie wagi',
          'subtitle': 'Bilans 0 kcal • Pełna stabilizacja wagi',
          'tag': 'Zero deficytu/nadwyżki',
        },
      ];
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Tempo na tydzień',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Wybierz tempo zmian, które jest dla Ciebie najbardziej komfortowe.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Deduced Goal Header Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  goal == WeightGoal.reduction
                      ? Icons.trending_down_rounded
                      : (goal == WeightGoal.surplus
                          ? Icons.trending_up_rounded
                          : Icons.check_circle_outline_rounded),
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal == WeightGoal.reduction
                          ? 'Cel: Redukcja (${diff.toStringAsFixed(1)} kg do zrzucenia)'
                          : (goal == WeightGoal.surplus
                              ? 'Cel: Budowa masy (+${diff.toStringAsFixed(1)} kg do zyskania)'
                              : 'Cel: Utrzymanie aktualnej masy'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Z ${_weightKg.toStringAsFixed(1)} kg ➔ ${_targetWeightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Pace Options
        ...paceOptions.map((opt) {
          final double paceVal = (opt['pace'] as num).toDouble();
          final bool isSelected = (_weeklyPaceKg - paceVal).abs() < 0.05;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => setState(() => _weeklyPaceKg = paceVal),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                opt['title'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  opt['tag'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 10),

        // Time to Goal Forecast Banner
        if (plan.estimatedWeeks > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withOpacity(0.25),
                        AppColors.primary.withOpacity(0.08),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prognoza osiągnięcia celu',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Osiągniesz cel za ${plan.estimatedWeeks} ${plan.estimatedWeeks == 1 ? "tydzień" : (plan.estimatedWeeks < 5 ? "tygodnie" : "tygodni")}!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Dzienny bilans kalorii: ${plan.dailyCalories} kcal (${plan.calorieOffset >= 0 ? "+" : ""}${plan.calorieOffset} kcal/dzień)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // STEP 5: Podsumowanie i wyliczenia
  Widget _buildStepSummary(bool isDark, NutritionCalculationResult plan) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text(
          'Twój spersonalizowany plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Wyliczone na podstawie wzoru Mifflina-St Jeor oraz wybranego tempa.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Main Target Calories Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.heroCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              const Text(
                'DZIENNY CEL KALORYCZNY',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.dailyCalories} kcal',
                style: const TextStyle(
                  color: AppColors.calories,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'BMR: ${plan.bmr} kcal • TDEE: ${plan.tdee} kcal (${plan.calorieOffset >= 0 ? "+" : ""}${plan.calorieOffset} kcal)',
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              if (plan.estimatedWeeks > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainerDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Szacowany czas do celu: ${plan.estimatedWeeks} tyg. • ${_weeklyPaceKg.toStringAsFixed(2)} kg/tydz.',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Macronutrients Grid
        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                label: 'Białko (2.0g/kg)',
                value: '${plan.proteinGrams} g',
                color: AppColors.proteinOn(context),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                label: 'Węglowodany',
                value: '${plan.carbsGrams} g',
                color: AppColors.carbsOn(context),
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMacroCard(
                label: 'Tłuszcze (25% kcal)',
                value: '${plan.fatGrams} g',
                color: AppColors.fatOn(context),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMacroCard(
                label: 'Woda (35ml/kg)',
                value: '${plan.waterGoalMl} ml',
                color: AppColors.waterOn(context),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
