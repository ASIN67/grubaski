import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Material 3 theme with OLED surfaces and electric-violet actions.
class AppTheme {
  const AppTheme._();

  static ThemeData get lightMode => lightTheme;
  static ThemeData get darkMode => darkTheme;
  static final lightTheme = _buildTheme(Brightness.light);
  static final darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final raised =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final text =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final mutedText =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primaryOnLight;
    final action = isDark ? AppColors.primary : AppColors.primaryOnLight;
    final onAction = isDark ? AppColors.darkBackground : Colors.white;
    final selectedSurface = isDark
        ? AppColors.primaryContainerDark
        : AppColors.primaryContainerLight;
    final error = isDark ? AppColors.error : AppColors.errorOnLight;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: accent,
      onPrimary: onAction,
      primaryContainer: selectedSurface,
      onPrimaryContainer: accent,
      secondary: isDark ? AppColors.secondary : AppColors.primaryOnLight,
      onSecondary: onAction,
      secondaryContainer: selectedSurface,
      onSecondaryContainer: accent,
      tertiary: isDark ? AppColors.tertiary : AppColors.primaryOnLight,
      onTertiary: onAction,
      surface: surface,
      surfaceDim: background,
      surfaceBright: raised,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: raised,
      surfaceContainerHighest: raised,
      surfaceTint: Colors.transparent,
      onSurface: text,
      onSurfaceVariant: secondaryText,
      outline: mutedText,
      outlineVariant: border,
      error: error,
      onError: onAction,
    );

    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: border),
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: border),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: brightness,
          systemNavigationBarColor: surface,
          systemNavigationBarDividerColor: surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: selectedSurface,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : mutedText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : secondaryText,
          );
        }),
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: accent,
        labelColor: accent,
        unselectedLabelColor: secondaryText,
        labelStyle: labelStyle,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        iconColor: secondaryText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: mutedText),
        labelStyle: TextStyle(color: secondaryText),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(accent, 1.5),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: action,
          foregroundColor: onAction,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: labelStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: action,
          foregroundColor: onAction,
          minimumSize: const Size(64, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: labelStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(64, 48),
          padding: buttonPadding,
          side: BorderSide(color: border),
          shape: buttonShape,
          textStyle: labelStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: labelStyle,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: onAction,
        elevation: 2,
        shape: buttonShape,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? selectedSurface
                  : surface),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? accent : secondaryText),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? raised : AppColors.lightTextPrimary,
        actionTextColor: AppColors.primaryLight,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: buttonShape,
        elevation: 4,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        elevation: 8,
        shape: dialogShape,
        titleTextStyle:
            TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: selectedSurface,
        headerForegroundColor: accent,
        shape: dialogShape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: border),
        ),
        showDragHandle: true,
        dragHandleColor: mutedText,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: text,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: text),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryText),
        bodySmall: TextStyle(fontSize: 12, color: mutedText),
        labelLarge: labelStyle.copyWith(color: text),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondaryText,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: mutedText,
        ),
      ),
    );
  }
}
