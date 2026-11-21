import 'package:intl/intl.dart';

/// Helper utility for consistent date manipulation, Hive dateKey generation ('YYYY-MM-DD'),
/// and Polish localization formatting.
class DateFormatter {
  const DateFormatter._();

  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');

  /// Converts a [DateTime] into a standardized Hive date key string ('YYYY-MM-DD').
  static String toDateKey(DateTime date) {
    return _keyFormat.format(date);
  }

  /// Parses a standardized date key string ('YYYY-MM-DD') back into a [DateTime].
  static DateTime fromDateKey(String key) {
    return _keyFormat.parse(key);
  }

  /// Returns user-friendly Polish date string ('Dzisiaj', 'Wczoraj', 'Jutro' or 'Poniedziałek, 12 października').
  static String formatPolishDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = DateTime.utc(date.year, date.month, date.day);

    final differenceInDays = target.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Dzisiaj';
    } else if (differenceInDays == -1) {
      return 'Wczoraj';
    } else if (differenceInDays == 1) {
      return 'Jutro';
    } else {
      // Polish formatted localized date string
      final dayNames = [
        'poniedziałek',
        'wtorek',
        'środa',
        'czwartek',
        'piątek',
        'sobota',
        'niedziela'
      ];
      final monthNames = [
        'stycznia',
        'lutego',
        'marca',
        'kwietnia',
        'maja',
        'czerwca',
        'lipca',
        'sierpnia',
        'września',
        'października',
        'listopada',
        'grudnia'
      ];

      final dayName = dayNames[date.weekday - 1];
      final monthName = monthNames[date.month - 1];

      return '$dayName, ${date.day} $monthName';
    }
  }

  /// Short Polish date for chart axes (e.g. '15.10').
  static String formatChartDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}
