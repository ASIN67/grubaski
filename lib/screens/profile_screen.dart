import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/app_update_service.dart';
import '../services/csv_export_service.dart';
import '../services/hive_service.dart';
import '../utils/app_colors.dart';
import '../utils/nutrition_calculator.dart';
import '../widgets/update_prompt_dialog.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';

/// Screen presenting user biometrics summary, goal configuration modal with live recalculation,
/// ThemeMode switcher (System/Light/Dark), CSV export with native share sheet,
/// and local data clearing.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isExporting = false;
  bool _isCheckingUpdate = false;
  String _appVersion = '1.0.1';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info =
          await ref.read(appUpdateServiceProvider).getCurrentVersionInfo();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkForUpdateManual() async {
    setState(() => _isCheckingUpdate = true);

    // On iOS and Web PWA, updates are silent and automatic via Service Worker
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wersja na iOS i przeglądarki (PWA) aktualizuje się automatycznie w tle. Masz aktualną wersję (v$_appVersion).',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      return;
    }

    try {
      final service = ref.read(appUpdateServiceProvider);
      final result = await service.checkForUpdate();
      if (!mounted) return;

      setState(() => _isCheckingUpdate = false);

      if (result.hasUpdate && result.latestRelease != null) {
        await UpdatePromptDialog.show(context, release: result.latestRelease!);
      } else if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aplikacja jest aktualna! Korzystasz z najnowszej wersji (v${result.currentVersion}).',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd sprawdzania aktualizacji: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      const service = CsvExportService();
      await service.exportAndShareDiary();
    } catch (e) {
      debugPrint('Failed to export CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się wyeksportować danych do pliku CSV.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showEditGoalsSheet(UserProfile profile) async {
    Gender selectedGender = profile.gender;
    int selectedAge = profile.age;
    double startWeight = profile.startWeightKg;
    double targetWeight = profile.targetWeightKg;
    double height = profile.heightCm;
    ActivityLevel activity = profile.activityLevel;
    double weeklyPace = profile.weeklyPaceKg;

    final ageController = TextEditingController(text: selectedAge.toString());
    final weightController =
        TextEditingController(text: startWeight.toStringAsFixed(1));
    final targetWeightController =
        TextEditingController(text: targetWeight.toStringAsFixed(1));
    final heightController =
        TextEditingController(text: height.toStringAsFixed(0));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final currentGoal = NutritionCalculator.deduceGoal(
            currentWeightKg: startWeight,
            targetWeightKg: targetWeight,
          );

          // Live recalculated nutrition targets
          final preview = NutritionCalculator.calculate(
            gender: selectedGender,
            age: selectedAge,
            weightKg: startWeight,
            heightCm: height,
            activityLevel: activity,
            targetWeightKg: targetWeight,
            weeklyPaceKg: weeklyPace,
          );

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edycja parametrów i celów',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Inputs: Waga, Cel wagi
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Waga aktualna (kg)',
                              suffixText: 'kg',
                            ),
                            onChanged: (v) {
                              final p = double.tryParse(v.replaceAll(',', '.'));
                              if (p != null && p > 30) {
                                setModalState(() => startWeight = p);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: targetWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Waga docelowa (kg)',
                              suffixText: 'kg',
                            ),
                            onChanged: (v) {
                              final p = double.tryParse(v.replaceAll(',', '.'));
                              if (p != null && p > 30) {
                                setModalState(() => targetWeight = p);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Automatycznie rozpoznany cel badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentGoal == WeightGoal.reduction
                                ? Icons.trending_down_rounded
                                : (currentGoal == WeightGoal.surplus
                                    ? Icons.trending_up_rounded
                                    : Icons.check_circle_outline_rounded),
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              currentGoal == WeightGoal.reduction
                                  ? 'Automatyczny cel: Redukcja (${(startWeight - targetWeight).abs().toStringAsFixed(1)} kg)'
                                  : (currentGoal == WeightGoal.surplus
                                      ? 'Automatyczny cel: Budowa masy (+${(targetWeight - startWeight).abs().toStringAsFixed(1)} kg)'
                                      : 'Automatyczny cel: Utrzymanie obecnej wagi'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tempo na tydzień
                    if (currentGoal != WeightGoal.maintenance) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tempo na tydzień',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${weeklyPace.toStringAsFixed(2)} kg/tydz. (${preview.calorieOffset >= 0 ? "+" : ""}${preview.calorieOffset} kcal)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: weeklyPace.clamp(
                          currentGoal == WeightGoal.reduction ? 0.25 : 0.1,
                          currentGoal == WeightGoal.reduction ? 1.0 : 0.6,
                        ),
                        min: currentGoal == WeightGoal.reduction ? 0.25 : 0.1,
                        max: currentGoal == WeightGoal.reduction ? 1.0 : 0.6,
                        divisions: currentGoal == WeightGoal.reduction ? 3 : 5,
                        label: '${weeklyPace.toStringAsFixed(2)} kg/tydz.',
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setModalState(() => weeklyPace = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Poziom aktywności selector
                    const Text(
                      'Aktywność fizyczna',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ActivityLevel>(
                          value: activity,
                          isExpanded: true,
                          dropdownColor:
                              isDark ? AppColors.darkCard : AppColors.lightCard,
                          items: ActivityLevel.values.map((a) {
                            return DropdownMenuItem(
                              value: a,
                              child: Text(
                                a.displayName,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newAct) {
                            if (newAct != null) {
                              setModalState(() => activity = newAct);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Wzrost i Wiek
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Wzrost (cm)',
                              suffixText: 'cm',
                            ),
                            onChanged: (v) {
                              final p = double.tryParse(v.replaceAll(',', '.'));
                              if (p != null && p > 80) {
                                setModalState(() => height = p);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Wiek (lata)',
                              suffixText: 'lat',
                            ),
                            onChanged: (v) {
                              final p = int.tryParse(v);
                              if (p != null && p > 10) {
                                setModalState(() => selectedAge = p);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Live preview calculation card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardElevated
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Przeliczone zapotrzebowanie:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (preview.estimatedWeeks > 0)
                                    Text(
                                      'Cel za ok. ${preview.estimatedWeeks} tyg.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${preview.dailyCalories} kcal',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.caloriesOn(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniMacro('B', '${preview.proteinGrams}g',
                                  AppColors.proteinOn(context)),
                              _buildMiniMacro('W', '${preview.carbsGrams}g',
                                  AppColors.carbsOn(context)),
                              _buildMiniMacro('T', '${preview.fatGrams}g',
                                  AppColors.fatOn(context)),
                              _buildMiniMacro(
                                  'Woda',
                                  '${preview.waterGoalMl}ml',
                                  AppColors.waterOn(context)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(userProfileProvider.notifier)
                              .updateBiometrics(
                                gender: selectedGender,
                                age: selectedAge,
                                startWeightKg: startWeight,
                                targetWeightKg: targetWeight,
                                heightCm: height,
                                activityLevel: activity,
                                goal: currentGoal,
                                weeklyPaceKg: weeklyPace,
                                recalculateGoals: true,
                              );

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Zaktualizowano profil i cele.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Zapisz zmiany'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Flexible(child: Text('Wyczyść wszystkie dane')),
          ],
        ),
        content: const Text(
          'Czy na pewno chcesz usunąć wszystkie zapisane posiłki, pomiary wagi i obwodów ciała, historię nawodnienia i profil użytkownika?\n\nTej operacji nie można cofnąć.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Usuń wszystko'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await HiveService.instance.clearAllData();
      await ref.read(userProfileProvider.notifier).reloadProfile();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil i ustawienia',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Biometrics & Nutritional Targets Card
          if (userProfile != null) ...[
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                              child: Icon(
                                userProfile.gender == Gender.male
                                    ? Icons.male
                                    : Icons.female,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.gender.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${userProfile.age} lat • ${userProfile.heightCm.toInt()} cm',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppColors.primary),
                          tooltip: 'Edytuj parametry',
                          onPressed: () => _showEditGoalsSheet(userProfile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    _buildProfileRow('Aktualna waga',
                        '${userProfile.startWeightKg.toStringAsFixed(1)} kg'),
                    _buildProfileRow('Waga docelowa',
                        '${userProfile.targetWeightKg.toStringAsFixed(1)} kg'),
                    _buildProfileRow('Cel', userProfile.goal.displayName),
                    if (userProfile.goal != WeightGoal.maintenance)
                      _buildProfileRow('Tempo',
                          '${userProfile.weeklyPaceKg.toStringAsFixed(2)} kg / tydzień'),
                    _buildProfileRow(
                        'Aktywność', userProfile.activityLevel.displayName),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'Dzienne zapotrzebowanie',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroPill(
                          label: 'Kalorie',
                          value: '${userProfile.dailyCaloriesGoal}',
                          unit: 'kcal',
                          color: AppColors.caloriesOn(context),
                        ),
                        _buildMacroPill(
                          label: 'Białko',
                          value: '${userProfile.proteinGoalGrams}',
                          unit: 'g',
                          color: AppColors.proteinOn(context),
                        ),
                        _buildMacroPill(
                          label: 'Węgle',
                          value: '${userProfile.carbsGoalGrams}',
                          unit: 'g',
                          color: AppColors.carbsOn(context),
                        ),
                        _buildMacroPill(
                          label: 'Tłuszcze',
                          value: '${userProfile.fatGoalGrams}',
                          unit: 'g',
                          color: AppColors.fatOn(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. Account & Supabase Cloud Sync Card
          _buildAccountCard(context, authState, isDark),
          const SizedBox(height: 20),

          // 3. Appearance / Theme Mode Switcher Card
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        'Motyw aplikacji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Jasny'),
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Ciemny'),
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (set) {
                      ref.read(themeProvider.notifier).setThemeMode(set.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Export Data to CSV
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined,
                          color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        'Eksport danych',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pobierz pełną historię posiłków w formacie CSV z polskimi nazwami kolumn i kodowaniem UTF-8.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _exportCsv,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share_outlined),
                      label: Text(_isExporting
                          ? 'Generowanie...'
                          : 'Eksportuj do CSV (Udostępnij)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. App Updates & In-App Auto-Updater
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.system_update_rounded,
                              color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Aktualizacje aplikacji',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v$_appVersion',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
                        ? 'Wersja na iOS i przeglądarki (PWA) pobiera poprawki i nowości automatycznie w tle przy każdym otwarciu.'
                        : 'Pobieraj nowości i poprawki automatycznie bez potrzeby ponownego ściągania aplikacji ze strony.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCheckingUpdate ? null : _checkForUpdateManual,
                      icon: _isCheckingUpdate
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(_isCheckingUpdate
                          ? 'Sprawdzanie...'
                          : 'Sprawdź dostępność aktualizacji'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. Data Management & Clear
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.delete_forever_outlined,
                          color: AppColors.error),
                      SizedBox(width: 10),
                      Text(
                        'Zarządzanie pamięcią',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wszystkie dane są przechowywane lokalnie na urządzeniu w bazie Hive (offline-first).',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showClearDataDialog,
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: AppColors.error),
                      label: const Text(
                        'Wyczyść wszystkie dane',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Footer info
          Center(
            child: Text(
              'Grubasek • Wersja $_appVersion (Offline-first)',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
      BuildContext context, UserAuthState authState, bool isDark) {
    if (authState.isAuthenticated) {
      final email = authState.email ?? 'Użytkownik Grubaska';
      final syncTimeStr = authState.lastSyncTime != null
          ? DateFormat('HH:mm, dd.MM').format(authState.lastSyncTime!)
          : null;

      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Konto w chmurze',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_done_rounded,
                                      size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Sync status text
              Row(
                children: [
                  Icon(
                    authState.isSyncing
                        ? Icons.sync
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: authState.isSyncing
                        ? AppColors.primaryLight
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.isSyncing
                          ? 'Trwa synchronizacja danych z chmurą...'
                          : syncTimeStr != null
                              ? 'Ostatnia synchronizacja: $syncTimeStr'
                              : 'Baza połączona z kontem w chmurze Supabase',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions: Sync + Sign Out
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: authState.isSyncing
                          ? null
                          : () async {
                              final success = await ref
                                  .read(authProvider.notifier)
                                  .syncData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Pomyślnie zsynchronizowano dane z chmurą!'
                                        : 'Nie udało się zsynchronizować danych.'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: success
                                        ? AppColors.primary
                                        : AppColors.error,
                                  ),
                                );
                              }
                            },
                      icon: authState.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(
                        authState.isSyncing
                            ? 'Synchronizuję...'
                            : 'Synchronizuj z chmurą',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSignOutDialog(context),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'Wyloguj',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Guest / Offline Mode Card
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Konto i chmura',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Tryb gościa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Zaloguj się, aby tworzyć bezpieczną kopię zapasową swoich posiłków, synchronizować historię między urządzeniami i korzystać ze wspólnej bazy produktów.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'Zaloguj / Zarejestruj się',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wylogowanie z chmury'),
        content: const Text(
          'Czy na pewno chcesz się wylogować? Twoje lokalne dane i historia w telefonie pozostaną nienaruszone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Wyloguj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wylogowano z konta w chmurze.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildMiniMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextMuted
                : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
