import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/weight_provider.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';
import 'body_measurements_view.dart';

enum _ProgressView { weight, measurements }

/// Shows weight, calorie trends and body circumference history.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _ProgressView _view = _ProgressView.weight;

  Future<void> _showMeasurementsDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BodyMeasurementsDialog(),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisano pomiar obwodów.')),
      );
    }
  }

  Future<void> _showAddWeightDialog() async {
    final latestWeight = ref.read(latestWeightProvider)?.weightKg ??
        ref.read(userProfileProvider)?.startWeightKg ??
        70.0;

    final controller = TextEditingController(
      text: latestWeight > 0 ? latestWeight.toStringAsFixed(1) : '',
    );
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Zapisz wagę'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+([.,]\d{0,1})?')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Waga (kg)',
                    hintText: 'np. 74.5',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 20),
                  title: Text(
                    DateFormatter.formatPolishDisplayDate(selectedDate),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('pl', 'PL'),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Zmień'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () {
                  final text = controller.text.replaceAll(',', '.').trim();
                  final weight = double.tryParse(text);
                  if (weight != null && weight > 20 && weight < 400) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final text = controller.text.replaceAll(',', '.').trim();
      final weight = double.tryParse(text);
      if (weight != null) {
        await ref.read(weightProvider.notifier).logWeight(
              weightKg: weight,
              date: selectedDate,
            );

        // Also update biometrics in profile
        await ref
            .read(userProfileProvider.notifier)
            .updateBiometrics(startWeightKg: weight);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zapisano wagę: ${weight.toStringAsFixed(1)} kg'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeightView = _view == _ProgressView.weight;
    final onAdd = isWeightView ? _showAddWeightDialog : _showMeasurementsDialog;
    final addLabel = isWeightView ? 'Zapisz wagę' : 'Dodaj pomiar';
    final addIcon = isWeightView ? Icons.monitor_weight_outlined : Icons.add;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postępy'),
        actions: [
          if (isWeightView)
            IconButton(
              icon: const Icon(Icons.add_chart_rounded),
              tooltip: 'Dodaj pomiar wagi',
              onPressed: _showAddWeightDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: SegmentedButton<_ProgressView>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _ProgressView.weight,
                  icon: Icon(Icons.monitor_weight_outlined, size: 18),
                  label: Text('Waga'),
                ),
                ButtonSegment(
                  value: _ProgressView.measurements,
                  icon: Icon(Icons.straighten_outlined, size: 18),
                  label: Text('Obwody ciała'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) =>
                  setState(() => _view = selection.single),
            ),
          ),
          Expanded(
            child: isWeightView
                ? _buildWeightView(context)
                : const BodyMeasurementsView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: Icon(addIcon),
        label: Text(addLabel),
      ),
    );
  }

  Widget _buildWeightView(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final weightEntries = ref.watch(weightChartEntriesProvider);
    final latestWeightEntry = ref.watch(latestWeightProvider);
    final totalWeightChange = ref.watch(weightChangeProvider);
    final diaryRepo = ref.watch(diaryRepositoryProvider);

    // Compute BMI metrics
    final double currentWeight =
        latestWeightEntry?.weightKg ?? userProfile?.startWeightKg ?? 70.0;
    final double heightCm = userProfile?.heightCm ?? 175.0;
    final double heightM = heightCm / 100.0;
    final double bmi =
        (heightM > 0) ? (currentWeight / (heightM * heightM)) : 0.0;
    final double targetWeight = userProfile?.targetWeightKg ?? 70.0;
    final double diffToGoal = currentWeight - targetWeight;

    final double calorieGoal =
        userProfile?.dailyCaloriesGoal.toDouble() ?? 2000.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(weightProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // 1. BMI & Target Weight Card
          _buildBmiCard(
            context,
            bmi: bmi,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            diffToGoal: diffToGoal,
            weightChange: totalWeightChange,
          ),

          const SizedBox(height: 20),

          // 2. Weight History Line Chart Section
          _buildWeightChartSection(
            context,
            weightEntries: weightEntries,
            targetWeight: targetWeight,
            onAddWeight: _showAddWeightDialog,
          ),

          const SizedBox(height: 20),

          // 3. 7-Day Calorie Bar Chart Section
          ListenableBuilder(
            listenable: diaryRepo.entriesListenable,
            builder: (context, _) {
              final today = DateTime.now();
              final days = [
                for (var offset = -6; offset <= 0; offset++)
                  DateUtils.addDaysToDate(today, offset),
              ];
              return _buildCalorieBarChartSection(
                context,
                daysData: [
                  for (final date in days)
                    MapEntry(date,
                        diaryRepo.getDailySummaryForDate(date).totalCalories),
                ],
                goalCalories: calorieGoal,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard(
    BuildContext context, {
    required double bmi,
    required double currentWeight,
    required double targetWeight,
    required double diffToGoal,
    required double? weightChange,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String bmiLabel;
    final Color bmiColor;
    if (bmi < 18.5) {
      bmiLabel = 'Niedowaga';
      bmiColor = AppColors.info;
    } else if (bmi < 25.0) {
      bmiLabel = 'Waga prawidłowa';
      bmiColor = AppColors.success;
    } else if (bmi < 30.0) {
      bmiLabel = 'Nadwaga';
      bmiColor = AppColors.warning;
    } else {
      bmiLabel = 'Otyłość';
      bmiColor = AppColors.error;
    }

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
                const Expanded(
                  child: Text(
                    'Wskaźnik BMI i waga',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bmiLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Twoje BMI',
                    value: bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                    color: bmiColor,
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Aktualna waga',
                    value: '${currentWeight.toStringAsFixed(1)} kg',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Cel',
                    value: '${targetWeight.toStringAsFixed(1)} kg',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Do osiągnięcia celu',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  diffToGoal.abs() < 0.1
                      ? 'Cel osiągnięty! 🎯'
                      : diffToGoal > 0
                          ? 'Pozostało ${diffToGoal.toStringAsFixed(1)} kg do zrzucenia'
                          : 'Pozostało ${diffToGoal.abs().toStringAsFixed(1)} kg do przybrania',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: diffToGoal.abs() < 0.1
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChartSection(
    BuildContext context, {
    required List<WeightEntry> weightEntries,
    required double targetWeight,
    required VoidCallback onAddWeight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                const Expanded(
                  child: Text(
                    'Waga w czasie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddWeight,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Zapisz'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (weightEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 48,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Brak pomiarów wagi.\nDotknij "Zapisz", aby wprowadzić swój pierwszy pomiar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: _buildLineChart(weightEntries, targetWeight, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<WeightEntry> entries,
    double targetWeight,
    bool isDark,
  ) {
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < entries.length; i++) {
      final w = entries[i].weightKg;
      spots.add(FlSpot(i.toDouble(), w));
      if (w < minY) minY = w;
      if (w > maxY) maxY = w;
    }

    if (targetWeight > 0) {
      if (targetWeight < minY) minY = targetWeight;
      if (targetWeight > maxY) maxY = targetWeight;
    }

    final double padding = math.max(1.0, (maxY - minY) * 0.15);
    minY = (minY - padding).clamp(20.0, 300.0);
    maxY = (maxY + padding).clamp(20.0, 300.0);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: math.max(1, (entries.length - 1)).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1, ((maxY - minY) / 4).roundToDouble()),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? AppColors.darkBorder.withOpacity(0.5)
                : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: math.max(1, ((maxY - minY) / 4).roundToDouble()),
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}kg',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) {
                  return const SizedBox.shrink();
                }
                // Show date for first, last, and every step
                if (entries.length > 5 &&
                    idx % ((entries.length / 4).ceil()) != 0 &&
                    idx != entries.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormatter.formatChartDate(entries[idx].date),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (targetWeight > 0)
              HorizontalLine(
                y: targetWeight,
                color: AppColors.primary.withOpacity(0.6),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 2),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) =>
                      'Cel ${targetWeight.toStringAsFixed(0)}kg',
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: isDark ? AppColors.darkCard : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBarChartSection(
    BuildContext context, {
    required List<MapEntry<DateTime, double>> daysData,
    required double goalCalories,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caloriesColor =
        isDark ? AppColors.caloriesLight : AppColors.caloriesDark;

    double maxCal = goalCalories;
    for (final item in daysData) {
      if (item.value > maxCal) maxCal = item.value;
    }
    final maxY = (maxCal * 1.15).ceilToDouble();

    final dayShortNames = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];

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
                const Expanded(
                  child: Text(
                    'Kalorie w ostatnich 7 dniach',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: caloriesColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cel ${goalCalories.toInt()} kcal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: caloriesColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        math.max(500, (maxY / 4).roundToDouble()),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? AppColors.darkBorder.withOpacity(0.5)
                          : AppColors.lightBorder,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goalCalories,
                        color: caloriesColor.withOpacity(0.8),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: math.max(500, (maxY / 4).roundToDouble()),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= daysData.length) {
                            return const SizedBox.shrink();
                          }
                          final date = daysData[idx].key;
                          final dayLabel = dayShortNames[date.weekday - 1];
                          final isToday = date.day == DateTime.now().day &&
                              date.month == DateTime.now().month;

                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isToday ? FontWeight.bold : FontWeight.w500,
                                color: isToday
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(daysData.length, (i) {
                    final val = daysData[i].value;
                    final isOverGoal = val > goalCalories && goalCalories > 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          color: isOverGoal
                              ? AppColors.calorieOverflow
                              : caloriesColor,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
