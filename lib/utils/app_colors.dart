import 'package:flutter/material.dart';

/// Brand, surface, and nutrition colors shared by both themes.
abstract class AppColors {
  const AppColors._();

  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF7C3AED);
  static const primaryOnLight = Color(0xFF6D28D9);
  static const primaryContainerLight = Color(0xFFEDE5FF);
  static const primaryContainerDark = Color(0xFF30224D);

  static const secondary = Color(0xFFC1ACF1);
  static const tertiary = Color(0xFFB09BED);

  static const calories = Color(0xFFF97316);
  static const caloriesLight = Color(0xFFFB923C);
  static const caloriesDark = Color(0xFF9A3412);
  static const calorieOverflow = Color(0xFFEF4444);
  static const protein = Color(0xFF38BDF8);
  static const proteinLight = Color(0xFF60A5FA);
  static const proteinDark = Color(0xFF1D4ED8);
  static const carbs = Color(0xFFFBBF24);
  static const carbsLight = Color(0xFFFCD34D);
  static const carbsDark = Color(0xFF92400E);
  static const fat = Color(0xFFFB7185);
  static const fatLight = Color(0xFFFDA4AF);
  static const fatDark = Color(0xFFBE123C);
  static const water = Color(0xFF06B6D4);
  static const waterLight = Color(0xFF22D3EE);
  static const waterDark = Color(0xFF0E7490);
  static const waterBackground = Color(0xFFCFFAFE);
  static const fiber = Color(0xFF34D399);
  static const fiberDark = Color(0xFF047857);

  static const caloriesGradient = LinearGradient(
    colors: [caloriesLight, calorieOverflow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const proteinGradient = LinearGradient(
    colors: [protein, proteinLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const carbsGradient = LinearGradient(
    colors: [carbs, Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fatGradient = LinearGradient(
    colors: [fat, Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const waterGradient = LinearGradient(
    colors: [waterLight, water],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCardGradient = LinearGradient(
    colors: [Color(0xFF211A33), darkCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightBackground = Color(0xFFF9F7FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF2EFF7);
  static const lightCard = lightSurface;
  static const lightTextPrimary = Color(0xFF1D1927);
  static const lightTextSecondary = Color(0xFF514A5F);
  static const lightTextMuted = Color(0xFF655D73);
  static const lightBorder = Color(0xFFE0D9EA);
  static const lightDivider = Color(0xFFECE7F1);

  static const darkBackground = Color(0xFF090A0F);
  static const darkSurface = Color(0xFF13141C);
  static const darkSurfaceVariant = Color(0xFF1A1B26);
  static const darkCard = darkSurface;
  static const darkCardElevated = darkSurfaceVariant;
  static const darkTextPrimary = Color(0xFFF5F3FA);
  static const darkTextSecondary = Color(0xFFBFBACD);
  static const darkTextMuted = Color(0xFFA19BAF);
  static const darkBorder = Color(0xFF252736);
  static const darkDivider = darkBorder;
  static const darkProgressTrack = Color(0xFF332E46);

  static const success = fiber;
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFFB7185);
  static const errorOnLight = Color(0xFFB91C1C);
  static const info = proteinLight;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      _isDark(context) ? darkTextMuted : lightTextMuted;

  static Color cardBackground(BuildContext context) =>
      _isDark(context) ? darkCard : lightCard;

  static Color border(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;

  static Color caloriesOn(BuildContext context) =>
      _isDark(context) ? calories : caloriesDark;

  static Color proteinOn(BuildContext context) =>
      _isDark(context) ? protein : proteinDark;

  static Color carbsOn(BuildContext context) =>
      _isDark(context) ? carbs : carbsDark;

  static Color fatOn(BuildContext context) => _isDark(context) ? fat : fatDark;

  static Color waterOn(BuildContext context) =>
      _isDark(context) ? waterLight : waterDark;

  static Color fiberOn(BuildContext context) =>
      _isDark(context) ? fiber : fiberDark;
}
