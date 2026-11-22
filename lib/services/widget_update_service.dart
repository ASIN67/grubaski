import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that syncs current daily macro totals to Android Home Screen Widget.
class WidgetUpdateService {
  WidgetUpdateService._();
  static final WidgetUpdateService instance = WidgetUpdateService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.grubasek/apk_installer');

  /// Pushes current calories, macros, and hydration stats to shared preferences
  /// and asks the native Android AppWidgetProvider to refresh any placed widgets.
  Future<void> updateWidgetData({
    required int remainingCalories,
    required double proteinConsumed,
    required double carbsConsumed,
    required int waterConsumedMl,
    bool isOverCalories = false,
  }) async {
    // Widgets are supported on Android native devices
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('widget_remaining_kcal', remainingCalories.abs());
      await prefs.setString(
          'widget_protein', '${proteinConsumed.round()}g');
      await prefs.setString(
          'widget_carbs', '${carbsConsumed.round()}g');

      final waterDisplay = waterConsumedMl >= 1000
          ? '${(waterConsumedMl / 1000.0).toStringAsFixed(1)} L'
          : '$waterConsumedMl ml';
      await prefs.setString('widget_water', waterDisplay);
      await prefs.setBool('widget_is_over', isOverCalories);

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('updateWidget');
      }
    } catch (e) {
      debugPrint('WidgetUpdateService: Failed to update home widget ($e)');
    }
  }
}
