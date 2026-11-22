import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/water_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/widgets.dart';
import 'add_portion_sheet.dart';
import 'add_product_screen.dart';
import 'ai_meal_estimation_screen.dart';
import 'barcode_scanner_screen.dart';
import 'quick_add_sheet.dart';

/// Main daily diary screen presenting the interactive date selector,
/// calorie and macro summaries, hydration tracker, and 5 distinct meal category cards.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  void _navigateToAddProduct(
    BuildContext context, {
    required MealType mealType,
    required DateTime date,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          initialMealType: mealType,
          date: date,
          returnEntryOnAdd: true,
        ),
      ),
    );
  }

  void _navigateToScanner(BuildContext context, DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          date: date,
        ),
      ),
    );
  }

  void _editMealEntry(
    BuildContext context,
    MealEntry entry,
    DateTime selectedDate,
  ) {
    if (entry.product.isQuickAdd) {
      QuickAddSheet.show(
        context,
        date: selectedDate,
        initialMealType: entry.mealType,
        existingEntry: entry,
      );
      return;
    }
    AddPortionSheet.show(
      context,
      product: entry.product,
      initialMealType: entry.mealType,
      initialGrams: entry.grams,
      entryId: entry.id,
    );
  }

  Future<void> _handleMealAction(
    BuildContext context,
    WidgetRef ref, {
    required MealCardAction action,
    required DateTime date,
    required MealType mealType,
  }) async {
    switch (action) {
      case MealCardAction.aiEstimate:
        await AiMealEstimationScreen.open(
          context,
          initialDate: date,
          initialMealType: mealType,
        );
      case MealCardAction.quickAdd:
        await QuickAddSheet.show(
          context,
          date: date,
          initialMealType: mealType,
        );
      case MealCardAction.copyFromYesterday:
        await _copyMeal(
          context,
          ref,
          sourceDate: DateUtils.addDaysToDate(date, -1),
          sourceMealType: mealType,
          targetDate: date,
          targetMealType: mealType,
          emptyMessage: 'Wczoraj nie zapisano produktów w tym posiłku.',
        );
      case MealCardAction.copyToMeal:
        final destination = await showDialog<(DateTime, MealType)>(
          context: context,
          builder: (context) => _CopyMealDialog(
            sourceDate: date,
            sourceMealType: mealType,
          ),
        );
        if (destination == null || !context.mounted) return;
        final (targetDate, targetMealType) = destination;
        await _copyMeal(
          context,
          ref,
          sourceDate: date,
          sourceMealType: mealType,
          targetDate: targetDate,
          targetMealType: targetMealType,
          emptyMessage: 'Ten posiłek jest pusty.',
        );
    }
  }

  Future<void> _copyMeal(
    BuildContext context,
    WidgetRef ref, {
    required DateTime sourceDate,
    required MealType sourceMealType,
    required DateTime targetDate,
    required MealType targetMealType,
    required String emptyMessage,
  }) async {
    String message;
    try {
      final copies = await ref.read(diaryProvider.notifier).copyMeal(
            sourceDate: sourceDate,
            sourceMealType: sourceMealType,
            targetDate: targetDate,
            targetMealType: targetMealType,
          );
      message = copies.isEmpty
          ? emptyMessage
          : 'Skopiowano wpisy do posiłku „${targetMealType.displayName}” '
              '(${_dateLabel(targetDate)}).';
    } catch (_) {
      message = 'Nie udało się skopiować posiłku.';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryState = ref.watch(diaryProvider);
    final userProfile = ref.watch(userProfileProvider);
    final waterLog = ref.watch(waterProvider);
    final isToday =
        DateUtils.isSameDay(diaryState.selectedDate, DateTime.now());

    // Profile Targets (fallbacks if user profile is being initialized)
    final double caloriesGoal =
        userProfile?.dailyCaloriesGoal.toDouble() ?? 2000.0;
    final double proteinGoal =
        userProfile?.proteinGoalGrams.toDouble() ?? 150.0;
    final double carbsGoal = userProfile?.carbsGoalGrams.toDouble() ?? 250.0;
    final double fatGoal = userProfile?.fatGoalGrams.toDouble() ?? 65.0;
    final int waterGoal = userProfile?.waterGoalMl ?? 2500;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dziennik',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFEC4899)),
            tooltip: 'Oszacuj Makro AI',
            onPressed: () => AiMealEstimationScreen.open(
              context,
              initialDate: diaryState.selectedDate,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Passa i Osiągnięcia',
            onPressed: () => AchievementsSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Szybkie skanowanie',
            onPressed: () =>
                _navigateToScanner(context, diaryState.selectedDate),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Odśwież',
            onPressed: () {
              ref.read(diaryProvider.notifier).refresh();
              ref.read(waterProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(diaryProvider.notifier).refresh();
          ref.read(waterProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // 0. Streak & Habit Banner
            const StreakBannerWidget(),

            const SizedBox(height: 12),

            // 1. Horizontal Date Picker Bar
            DailyDatePickerBar(
              selectedDate: diaryState.selectedDate,
              onDateSelected: (date) {
                ref.read(diaryProvider.notifier).setSelectedDate(date);
              },
            ),

            const SizedBox(height: 16),

            // 2. Calorie and Macro Summary Dashboard Card
            CalorieSummaryCard(
              caloriesConsumed: diaryState.totalCalories,
              caloriesGoal: caloriesGoal,
              proteinConsumed: diaryState.totalProtein,
              proteinGoal: proteinGoal,
              carbsConsumed: diaryState.totalCarbs,
              carbsGoal: carbsGoal,
              fatConsumed: diaryState.totalFat,
              fatGoal: fatGoal,
            ),

            const SizedBox(height: 16),

            // 3. Hydration Tracker Card
            WaterTrackerCard(
              consumedMl: waterLog.amountMl,
              goalMl: waterGoal,
              onWaterDelta: (delta) {
                if (delta > 0) {
                  ref.read(waterProvider.notifier).addWater(delta);
                } else if (delta < 0) {
                  ref.read(waterProvider.notifier).removeWater(delta.abs());
                }
              },
            ),

            const SizedBox(height: 16),

            // Section Header: Posiłki with AI Assistant Shortcut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Posiłki',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: Color(0xFFEC4899),
                    ),
                    label: const Text(
                      'AI Asystent',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    onPressed: () => AiMealEstimationScreen.open(
                      context,
                      initialDate: diaryState.selectedDate,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. Five Standard Meal Expansion Cards
            ...MealType.values.map((mealType) {
              final entries = diaryState.entriesByMeal[mealType] ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: MealExpansionCard(
                  key: ValueKey('${diaryState.dateKey}_${mealType.name}'),
                  mealType: mealType,
                  entries: entries,
                  isInitiallyExpanded: true,
                  onAddProduct: () => _navigateToAddProduct(
                    context,
                    mealType: mealType,
                    date: diaryState.selectedDate,
                  ),
                  onDeleteEntry: (entry) {
                    ref.read(diaryProvider.notifier).removeEntry(entry.id);
                  },
                  onUndoDelete: (entry) {
                    ref.read(diaryProvider.notifier).undoRemoveEntry();
                  },
                  onTapEntry: (entry) => _editMealEntry(
                    context,
                    entry,
                    diaryState.selectedDate,
                  ),
                  canCopyFromYesterday: isToday,
                  onAction: (action) => _handleMealAction(
                    context,
                    ref,
                    action: action,
                    date: diaryState.selectedDate,
                    mealType: mealType,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${DateFormatter.formatChartDate(date)}.${date.year}';
}

class _CopyMealDialog extends StatefulWidget {
  final DateTime sourceDate;
  final MealType sourceMealType;

  const _CopyMealDialog({
    required this.sourceDate,
    required this.sourceMealType,
  });

  @override
  State<_CopyMealDialog> createState() => _CopyMealDialogState();
}

class _CopyMealDialogState extends State<_CopyMealDialog> {
  late DateTime _date;
  late MealType _mealType;

  @override
  void initState() {
    super.initState();
    _date = DateUtils.addDaysToDate(widget.sourceDate, 1);
    _mealType = widget.sourceMealType;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 3);
    final lastDate = DateTime(now.year + 2);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(firstDate) ? _date : firstDate,
      lastDate: _date.isAfter(lastDate) ? _date : lastDate,
      helpText: 'Wybierz dzień docelowy',
    );
    if (mounted && selected != null) {
      setState(() => _date = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNewDestination = !DateUtils.isSameDay(widget.sourceDate, _date) ||
        widget.sourceMealType != _mealType;

    return AlertDialog(
      scrollable: true,
      title: const Text('Skopiuj posiłek'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_dateLabel(_date)),
            onPressed: _selectDate,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Posiłek docelowy'),
            items: [
              for (final type in MealType.values)
                DropdownMenuItem(value: type, child: Text(type.displayName)),
            ],
            onChanged: (type) {
              if (type != null) setState(() => _mealType = type);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: hasNewDestination
              ? () => Navigator.pop(context, (_date, _mealType))
              : null,
          child: const Text('Skopiuj'),
        ),
      ],
    );
  }
}
