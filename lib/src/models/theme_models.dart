import 'package:flutter/material.dart';

/// Theme types for the cribbage game based on seasons and US secular holidays
enum ThemeType {
  // Seasons (Astronomical)
  spring, // Mar 20 - Jun 20
  summer, // Jun 21 - Sep 21
  fall, // Sep 22 - Dec 20
  winter, // Dec 21 - Mar 19

  // US Secular Holidays (take priority over seasons)
  newYear, // Jan 1
  mlkDay, // 3rd Monday in January
  valentinesDay, // Feb 14
  presidentsDay, // 3rd Monday in February
  piDay, // Mar 14
  idesOfMarch, // Mar 15
  stPatricksDay, // Mar 17
  memorialDay, // Last Monday in May
  independenceDay, // Jul 4
  laborDay, // 1st Monday in September
  halloween, // Oct 31
  thanksgiving, // 4th Thursday in November
  christmas, // Dec 25
}

/// Color scheme for a specific theme
class ThemeColors {
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color background;
  final Color surface;
  final Color cardBack;
  final Color boardPrimary;
  final Color boardSecondary;
  final Color accentLight;
  final Color accentDark;

  const ThemeColors({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.background,
    required this.surface,
    required this.cardBack,
    required this.boardPrimary,
    required this.boardSecondary,
    required this.accentLight,
    required this.accentDark,
  });
}

/// Complete theme configuration including colors and decorative elements
class CribbageTheme {
  final ThemeType type;
  final String name;
  final ThemeColors colors;
  final String icon; // Unicode emoji or symbol

  const CribbageTheme({
    required this.type,
    required this.name,
    required this.colors,
    required this.icon,
  });

  /// Convert to Flutter ThemeData
  ThemeData toThemeData() {
    final brightness = _calculateBrightness(colors.background);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: _getContrastColor(colors.primary),
        primaryContainer: colors.primaryVariant,
        onPrimaryContainer: _getContrastColor(colors.primaryVariant),
        secondary: colors.secondary,
        onSecondary: _getContrastColor(colors.secondary),
        secondaryContainer: colors.secondaryVariant,
        onSecondaryContainer: _getContrastColor(colors.secondaryVariant),
        tertiary: colors.boardPrimary,
        onTertiary: _getContrastColor(colors.boardPrimary),
        tertiaryContainer: colors.boardSecondary,
        onTertiaryContainer: _getContrastColor(colors.boardSecondary),
        error: const Color(0xFFB00020),
        onError: Colors.white,
        surface: colors.surface,
        onSurface: _getContrastColor(colors.surface),
        background: colors.background,
        onBackground: _getContrastColor(colors.background),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
      ),
    );
  }

  /// Calculate brightness based on background color
  Brightness _calculateBrightness(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  /// Get contrasting color for text on a background
  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
