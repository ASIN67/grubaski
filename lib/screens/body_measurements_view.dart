import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/body_measurements_entry.dart';
import '../providers/body_measurements_provider.dart';
import '../utils/date_formatter.dart';

final _measurementFormat = NumberFormat('0.#', 'pl');

enum _BodyPart {
  waist('Pas'),
  chest('Klatka piersiowa'),
  arm('Ramię (biceps)'),
  hips('Biodra'),
  thigh('Udo');

  const _BodyPart(this.label);

  final String label;

  double? valueFrom(BodyMeasurementsEntry entry) => switch (this) {
        waist => entry.waistCm,
        chest => entry.chestCm,
        arm => entry.armCm,
        hips => entry.hipsCm,
        thigh => entry.thighCm,
      };
}

class BodyMeasurementsView extends ConsumerWidget {
  const BodyMeasurementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(bodyMeasurementsProvider);
    final waistEntries =
        entries.where((entry) => entry.waistCm != null).toList();
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(bodyMeasurementsProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: entries.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WaistChartCard(entries: waistEntries.reversed.toList()),
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Historia pomiarów', style: textTheme.titleMedium),
                ],
              ],
            );
          }

          final entry = entries[index - 1];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations.formatFullDate(entry.date),
                      style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (final part in _BodyPart.values)
                        if (part.valueFrom(entry) case final double value)
                          Text(
                              '${part.label} ${_measurementFormat.format(value)} cm'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaistChartCard extends StatelessWidget {
  const _WaistChartCard({required this.entries});

  final List<BodyMeasurementsEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        Text('Obwód pasa', style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text('Dodaj pierwszy pomiar pasa, aby zobaczyć wykres.',
                  style: theme.textTheme.bodyMedium)
            else ...[
              Text('${_measurementFormat.format(entries.last.waistCm)} cm',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              SizedBox(height: 192, child: _buildChart(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstDay = _calendarDay(entries.first.date);
    final spots = [
      for (final entry in entries)
        FlSpot(
          _calendarDay(entry.date).difference(firstDay).inDays.toDouble(),
          entry.waistCm!,
        ),
    ];
    final minValue = spots.map((spot) => spot.y).reduce(math.min);
    final maxValue = spots.map((spot) => spot.y).reduce(math.max);
    final padding = math.max(2, (maxValue - minValue) * 0.1);
    final interval = math
        .max(1, ((maxValue - minValue + 2 * padding) / 4).ceil())
        .toDouble();
    final maxX = math.max(1.0, spots.last.x);
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant);

    const hiddenAxis = AxisTitles(sideTitles: SideTitles(showTitles: false));
    return Semantics(
      label: 'Wykres obwodu pasa w centymetrach',
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY:
              math.max(0, ((minValue - padding) / interval).floor() * interval),
          maxY: ((maxValue + padding) / interval).ceil() * interval,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: colors.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: hiddenAxis,
            topTitles: hiddenAxis,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: interval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(value.toInt().toString(), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: math.max(1, (maxX / 3).ceil()).toDouble(),
                getTitlesWidget: (value, meta) {
                  if (value > spots.last.x) return const SizedBox.shrink();
                  if (value != maxX && maxX - value < maxX / 8) {
                    return const SizedBox.shrink();
                  }
                  final date = firstDay.add(Duration(days: value.toInt()));
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                    child: Text(DateFormatter.formatChartDate(date),
                        style: labelStyle),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => colors.surfaceContainerHighest,
              getTooltipItems: (touched) => [
                for (final spot in touched)
                  LineTooltipItem(
                    '${DateFormatter.formatChartDate(entries[spot.spotIndex].date)}\n'
                    '${_measurementFormat.format(spot.y)} cm',
                    TextStyle(
                        color: colors.onSurface, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: colors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withOpacity(0.22),
                    colors.primary.withOpacity(0)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _calendarDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

class BodyMeasurementsDialog extends ConsumerStatefulWidget {
  const BodyMeasurementsDialog({super.key});

  @override
  ConsumerState<BodyMeasurementsDialog> createState() =>
      _BodyMeasurementsDialogState();
}

class _BodyMeasurementsDialogState
    extends ConsumerState<BodyMeasurementsDialog> {
  static final _measurementInput = RegExp(r'^\d{0,4}([.,]\d?)?$');

  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    for (final part in _BodyPart.values) part: TextEditingController(),
  };
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controllers.values.every((field) => field.text.trim().isEmpty)) {
      setState(() => _error = 'Podaj co najmniej jeden obwód.');
      return;
    }

    double? measurement(_BodyPart part) => _parse(_controllers[part]!.text);

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(bodyMeasurementsProvider.notifier)
          .save(BodyMeasurementsEntry(
            date: _date,
            waistCm: measurement(_BodyPart.waist),
            chestCm: measurement(_BodyPart.chest),
            armCm: measurement(_BodyPart.arm),
            hipsCm: measurement(_BodyPart.hips),
            thighCm: measurement(_BodyPart.thigh),
          ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Nie udało się zapisać pomiaru. Spróbuj ponownie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: const Text('Dodaj pomiar obwodów'),
        scrollable: true,
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(localizations.formatCompactDate(_date)),
              ),
              for (final part in _BodyPart.values)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers[part],
                    enabled: !_saving,
                    decoration: InputDecoration(
                        labelText: part.label, suffixText: 'cm'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: part == _BodyPart.thigh
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) =>
                          _measurementInput.hasMatch(newValue.text)
                              ? newValue
                              : oldValue),
                    ],
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) return null;
                      final value = _parse(text);
                      if (value == null || value <= 0 || value > 1000) {
                        return 'Podaj obwód większy od 0 i do 1000 cm.';
                      }
                      return null;
                    },
                  ),
                ),
              if (_error case final String error) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(error,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Zapisywanie…' : 'Zapisz'),
          ),
        ],
      ),
    );
  }
}
