import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

/// StateNotifier that manages and persists the application's [ThemeMode]
/// (system, light, dark) using Hive local storage.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _settingsThemeKey = 'theme_mode';

  ThemeNotifier() : super(_loadInitialTheme());

  static ThemeMode _loadInitialTheme() {
    try {
      final box = HiveService.instance.settingsBox;
      final savedValue = box.get(_settingsThemeKey);

      if (savedValue is String) {
        switch (savedValue.toLowerCase()) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
            return ThemeMode.system;
        }
      } else if (savedValue is int &&
          savedValue >= 0 &&
          savedValue < ThemeMode.values.length) {
        return ThemeMode.values[savedValue];
      }
    } catch (_) {
      // The settings box may not be available yet.
    }
    return ThemeMode.dark;
  }

  /// Sets and persists a new [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = HiveService.instance.settingsBox;
      await box.put(_settingsThemeKey, mode.name);
    } catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }

  /// Convenience toggle between Light and Dark mode.
  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

/// Global provider for application ThemeMode.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
