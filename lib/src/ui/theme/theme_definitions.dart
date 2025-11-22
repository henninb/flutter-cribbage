import 'package:flutter/material.dart';
import '../../models/theme_models.dart';

/// Predefined themes for all seasons and holidays
class ThemeDefinitions {
  // ========== SEASONAL THEMES ==========

  static const spring = CribbageTheme(
    type: ThemeType.spring,
    name: 'Spring Renewal',
    colors: ThemeColors(
      primary: Color(0xFF388E3C), // Fresh green (darker for better contrast)
      primaryVariant: Color(0xFF2E7D32), // Dark green
      secondary: Color(0xFFF9A825), // Yellow (sunshine)
      secondaryVariant: Color(0xFFF57F17), // Golden
      background: Color(0xFFF9FBE7), // Very light green background
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFAED581), // Light green
      boardPrimary: Color(0xFF66BB6A), // Medium green
      boardSecondary: Color(0xFF81C784), // Light green
      accentLight: Color(0xFFFFCDD2), // Pink (flowers)
      accentDark: Color(0xFF689F38), // Lime green
    ),
    icon: '🌸', // Cherry blossom
  );

  static const summer = CribbageTheme(
    type: ThemeType.summer,
    name: 'Summer Sun',
    colors: ThemeColors(
      primary: Color(0xFFF9A825), // Amber (sun) - darker for contrast
      primaryVariant: Color(0xFFF57F17), // Dark amber
      secondary: Color(0xFF0277BD), // Sky blue - darker for contrast
      secondaryVariant: Color(0xFF01579B), // Ocean blue
      background: Color(0xFFFFFDE7), // Very light yellow
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFFFD54F), // Yellow
      boardPrimary: Color(0xFFFFCA28), // Bright yellow
      boardSecondary: Color(0xFF4FC3F7), // Light blue
      accentLight: Color(0xFFB3E5FC), // Pale blue
      accentDark: Color(0xFFE65100), // Orange
    ),
    icon: '☀️', // Sun
  );

  static const fall = CribbageTheme(
    type: ThemeType.fall,
    name: 'Autumn Harvest',
    colors: ThemeColors(
      primary: Color(0xFFFF8A50), // Warm pumpkin orange
      primaryVariant: Color(0xFFE65100), // Deep pumpkin
      secondary: Color(0xFFFFB74D), // Harvest gold
      secondaryVariant: Color(0xFFFFA726), // Golden amber
      background: Color(0xFF1A0E0A), // Very dark brown (maximum contrast)
      surface: Color(0xFF2D1B16), // Dark chocolate brown
      cardBack: Color(0xFFFFCC80), // Light golden peach
      boardPrimary: Color(0xFFD84315), // Burnt orange/rust
      boardSecondary: Color(0xFFFFAB40), // Bright golden
      accentLight: Color(0xFFFFF3E0), // Cream/wheat
      accentDark: Color(0xFFBF360C), // Deep rust red
    ),
    icon: '🍂', // Fallen leaf
  );

  static const winter = CribbageTheme(
    type: ThemeType.winter,
    name: 'Winter Frost',
    colors: ThemeColors(
      primary: Color(0xFF1565C0), // Blue - darker for contrast
      primaryVariant: Color(0xFF0D47A1), // Dark blue
      secondary: Color(0xFF78909C), // Blue grey - darker
      secondaryVariant: Color(0xFF546E7A), // Dark blue grey
      background: Color(0xFF263238), // Dark blue-grey background
      surface: Color(0xFF37474F), // Dark surface
      cardBack: Color(0xFF90CAF9), // Light blue
      boardPrimary: Color(0xFF42A5F5), // Medium blue
      boardSecondary: Color(0xFF64B5F6), // Sky blue
      accentLight: Color(0xFFFFFFFF), // Snow white
      accentDark: Color(0xFF0D47A1), // Navy blue
    ),
    icon: '❄️', // Snowflake
  );

  // ========== HOLIDAY THEMES ==========

  static const newYear = CribbageTheme(
    type: ThemeType.newYear,
    name: 'New Year\'s Celebration',
    colors: ThemeColors(
      primary: Color(0xFFFFD700), // Gold
      primaryVariant: Color(0xFFDAA520), // Goldenrod
      secondary: Color(0xFF9C27B0), // Purple
      secondaryVariant: Color(0xFF7B1FA2), // Dark purple
      background: Color(0xFFFFF8E1), // Light gold
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFFFE082), // Light gold
      boardPrimary: Color(0xFFFFD54F), // Gold
      boardSecondary: Color(0xFFBA68C8), // Purple
      accentLight: Color(0xFFFFFFFF), // White (confetti)
      accentDark: Color(0xFF311B92), // Deep purple
    ),
    icon: '🎉', // Party popper
  );

  static const mlkDay = CribbageTheme(
    type: ThemeType.mlkDay,
    name: 'MLK Day - Equality',
    colors: ThemeColors(
      primary: Color(0xFF1976D2), // Blue (equality)
      primaryVariant: Color(0xFF0D47A1), // Navy blue
      secondary: Color(0xFF757575), // Grey (unity)
      secondaryVariant: Color(0xFF424242), // Dark grey
      background: Color(0xFFE3F2FD), // Light blue
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90CAF9), // Sky blue
      boardPrimary: Color(0xFF1E88E5), // Blue
      boardSecondary: Color(0xFF9E9E9E), // Grey
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF000000), // Black
    ),
    icon: '✊', // Raised fist
  );

  static const valentinesDay = CribbageTheme(
    type: ThemeType.valentinesDay,
    name: 'Valentine\'s Hearts',
    colors: ThemeColors(
      primary: Color(0xFFE91E63), // Pink
      primaryVariant: Color(0xFFC2185B), // Dark pink
      secondary: Color(0xFFF44336), // Red
      secondaryVariant: Color(0xFFD32F2F), // Dark red
      background: Color(0xFFFCE4EC), // Light pink
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFF8BBD0), // Rose
      boardPrimary: Color(0xFFEC407A), // Pink
      boardSecondary: Color(0xFFEF5350), // Red
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF880E4F), // Burgundy
    ),
    icon: '💕', // Two hearts
  );

  static const presidentsDay = CribbageTheme(
    type: ThemeType.presidentsDay,
    name: 'Presidents\' Day',
    colors: ThemeColors(
      primary: Color(0xFF1565C0), // Presidential blue
      primaryVariant: Color(0xFF0D47A1), // Navy
      secondary: Color(0xFFD32F2F), // Red
      secondaryVariant: Color(0xFFB71C1C), // Dark red
      background: Color(0xFFF5F5F5), // Light grey
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90CAF9), // Light blue
      boardPrimary: Color(0xFF1976D2), // Blue
      boardSecondary: Color(0xFFE57373), // Red
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF0D47A1), // Navy
    ),
    icon: '🇺🇸', // US Flag
  );

  static const piDay = CribbageTheme(
    type: ThemeType.piDay,
    name: 'Pi Day 3.14159...',
    colors: ThemeColors(
      primary: Color(0xFF1976D2), // Math blue
      primaryVariant: Color(0xFF0D47A1), // Dark blue
      secondary: Color(0xFFFF6F00), // Orange (circle)
      secondaryVariant: Color(0xFFE65100), // Dark orange
      background: Color(0xFFE3F2FD), // Light blue
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90CAF9), // Light blue
      boardPrimary: Color(0xFF42A5F5), // Blue
      boardSecondary: Color(0xFFFFB74D), // Light orange
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF01579B), // Navy blue
    ),
    icon: '🥧', // Pie
  );

  static const idesOfMarch = CribbageTheme(
    type: ThemeType.idesOfMarch,
    name: 'Ides of March - Beware!',
    colors: ThemeColors(
      primary: Color(0xFF8E24AA), // Imperial purple
      primaryVariant: Color(0xFF6A1B9A), // Dark purple
      secondary: Color(0xFFD32F2F), // Roman red (blood)
      secondaryVariant: Color(0xFFB71C1C), // Dark red
      background: Color(0xFFF3E5F5), // Light purple
      surface: Color(0xFFFFFFFF), // White (marble)
      cardBack: Color(0xFFCE93D8), // Light purple
      boardPrimary: Color(0xFFAB47BC), // Purple
      boardSecondary: Color(0xFFEF5350), // Light red
      accentLight: Color(0xFFFFD700), // Gold (Roman)
      accentDark: Color(0xFF4A148C), // Deep purple
    ),
    icon: '🗡️', // Dagger
  );

  static const stPatricksDay = CribbageTheme(
    type: ThemeType.stPatricksDay,
    name: 'St. Patrick\'s Green',
    colors: ThemeColors(
      primary: Color(0xFF43A047), // Green
      primaryVariant: Color(0xFF2E7D32), // Dark green
      secondary: Color(0xFFFFD700), // Gold
      secondaryVariant: Color(0xFFDAA520), // Goldenrod
      background: Color(0xFFC8E6C9), // Light green
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF81C784), // Green
      boardPrimary: Color(0xFF66BB6A), // Medium green
      boardSecondary: Color(0xFFFFE082), // Gold
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF1B5E20), // Deep green
    ),
    icon: '☘️', // Shamrock
  );

  static const memorialDay = CribbageTheme(
    type: ThemeType.memorialDay,
    name: 'Memorial Day',
    colors: ThemeColors(
      primary: Color(0xFF1565C0), // Blue
      primaryVariant: Color(0xFF0D47A1), // Navy
      secondary: Color(0xFFD32F2F), // Red
      secondaryVariant: Color(0xFFB71C1C), // Dark red
      background: Color(0xFFECEFF1), // Light grey
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90CAF9), // Light blue
      boardPrimary: Color(0xFF1976D2), // Blue
      boardSecondary: Color(0xFFE57373), // Light red
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF37474F), // Blue grey
    ),
    icon: '🎖️', // Military medal
  );

  static const independenceDay = CribbageTheme(
    type: ThemeType.independenceDay,
    name: '4th of July',
    colors: ThemeColors(
      primary: Color(0xFF1565C0), // Blue
      primaryVariant: Color(0xFF0D47A1), // Navy
      secondary: Color(0xFFD32F2F), // Red
      secondaryVariant: Color(0xFFB71C1C), // Dark red
      background: Color(0xFFF5F5F5), // White
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90CAF9), // Light blue
      boardPrimary: Color(0xFF1976D2), // Blue
      boardSecondary: Color(0xFFE57373), // Light red
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFFB71C1C), // Dark red
    ),
    icon: '🎆', // Fireworks
  );

  static const laborDay = CribbageTheme(
    type: ThemeType.laborDay,
    name: 'Labor Day',
    colors: ThemeColors(
      primary: Color(0xFF455A64), // Blue grey (working)
      primaryVariant: Color(0xFF263238), // Dark blue grey
      secondary: Color(0xFFFFB300), // Amber (sunset)
      secondaryVariant: Color(0xFFF57C00), // Orange
      background: Color(0xFFECEFF1), // Light grey
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFF90A4AE), // Grey blue
      boardPrimary: Color(0xFF546E7A), // Blue grey
      boardSecondary: Color(0xFFFFCC80), // Light orange
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF37474F), // Dark blue grey
    ),
    icon: '⚒️', // Hammer and pick
  );

  static const halloween = CribbageTheme(
    type: ThemeType.halloween,
    name: 'Halloween Spooky',
    colors: ThemeColors(
      primary: Color(0xFFFF6F00), // Orange
      primaryVariant: Color(0xFFE65100), // Dark orange
      secondary: Color(0xFF7E57C2), // Purple
      secondaryVariant: Color(0xFF512DA8), // Dark purple
      background: Color(0xFF212121), // Dark (night)
      surface: Color(0xFF424242), // Dark grey
      cardBack: Color(0xFFFFB74D), // Light orange
      boardPrimary: Color(0xFFFF8F00), // Pumpkin orange
      boardSecondary: Color(0xFF9575CD), // Purple
      accentLight: Color(0xFFFFFFFF), // White
      accentDark: Color(0xFF000000), // Black
    ),
    icon: '🎃', // Jack-o-lantern
  );

  static const thanksgiving = CribbageTheme(
    type: ThemeType.thanksgiving,
    name: 'Thanksgiving Harvest',
    colors: ThemeColors(
      primary: Color(0xFFD84315), // Burnt orange
      primaryVariant: Color(0xFFBF360C), // Dark orange
      secondary: Color(0xFF8D6E63), // Brown
      secondaryVariant: Color(0xFF5D4037), // Dark brown
      background: Color(0xFFFBE9E7), // Light orange
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFFFAB91), // Peach
      boardPrimary: Color(0xFFFF7043), // Coral
      boardSecondary: Color(0xFFA1887F), // Brown grey
      accentLight: Color(0xFFFFE0B2), // Cream
      accentDark: Color(0xFF6D4C41), // Deep brown
    ),
    icon: '🦃', // Turkey
  );

  static const christmas = CribbageTheme(
    type: ThemeType.christmas,
    name: 'Christmas Cheer',
    colors: ThemeColors(
      primary: Color(0xFFC62828), // Christmas red
      primaryVariant: Color(0xFFB71C1C), // Dark red
      secondary: Color(0xFF2E7D32), // Christmas green
      secondaryVariant: Color(0xFF1B5E20), // Dark green
      background: Color(0xFFFAFAFA), // Snow white
      surface: Color(0xFFFFFFFF), // White
      cardBack: Color(0xFFEF9A9A), // Light red
      boardPrimary: Color(0xFFE53935), // Red
      boardSecondary: Color(0xFF43A047), // Green
      accentLight: Color(0xFFFFFFFF), // White (snow)
      accentDark: Color(0xFFFFD700), // Gold
    ),
    icon: '🎄', // Christmas tree
  );

  /// Get all themes as a list
  static List<CribbageTheme> get allThemes => [
        spring,
        summer,
        fall,
        winter,
        newYear,
        mlkDay,
        valentinesDay,
        presidentsDay,
        piDay,
        idesOfMarch,
        stPatricksDay,
        memorialDay,
        independenceDay,
        laborDay,
        halloween,
        thanksgiving,
        christmas,
      ];

  /// Get theme by type
  static CribbageTheme getThemeByType(ThemeType type) {
    return allThemes.firstWhere((theme) => theme.type == type);
  }
}
