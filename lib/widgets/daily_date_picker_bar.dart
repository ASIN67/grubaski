import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/date_formatter.dart';

/// A sleek horizontal date selector bar featuring Polish relative labels
/// ('Dzisiaj', 'Wczoraj', 'Jutro'), chevron day navigation, a quick "Dzisiaj"
/// jump pill, and an interactive calendar modal picker.
class DailyDatePickerBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DailyDatePickerBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  void _goToPreviousDay() {
    onDateSelected(DateUtils.addDaysToDate(selectedDate, -1));
  }

  void _goToNextDay() {
    onDateSelected(DateUtils.addDaysToDate(selectedDate, 1));
  }

  void _goToToday() {
    final now = DateTime.now();
    onDateSelected(DateTime(now.year, now.month, now.day));
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(now.year - 3),
      lastDate: lastDate ?? DateTime(now.year + 2),
      locale: const Locale('pl', 'PL'),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryLabel = DateFormatter.formatPolishDisplayDate(selectedDate);
    final isRelative = primaryLabel == 'Dzisiaj' ||
        primaryLabel == 'Wczoraj' ||
        primaryLabel == 'Jutro';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Previous Day Button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 26),
            tooltip: 'Poprzedni dzień',
            splashRadius: 22,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            onPressed: _goToPreviousDay,
          ),

          // Center Interactive Date Area
          Expanded(
            child: InkWell(
              onTap: () => _openDatePicker(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          primaryLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (!_isToday) ...[
                          GestureDetector(
                            onTap: _goToToday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Dziś',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isRelative) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Next Day Button
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 26),
            tooltip: 'Następny dzień',
            splashRadius: 22,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            onPressed: _goToNextDay,
          ),

          // Open Calendar Modal Button
          Container(
            height: 24,
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            tooltip: 'Wybierz datę z kalendarza',
            splashRadius: 22,
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            onPressed: () => _openDatePicker(context),
          ),
        ],
      ),
    );
  }
}

/// Convenient alias for [DailyDatePickerBar].
typedef DatePickerBar = DailyDatePickerBar;
