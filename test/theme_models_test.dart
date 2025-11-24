import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/models/theme_models.dart';

void main() {
  group('CribbageTheme.toThemeData', () {
    const brightColors = ThemeColors(
      primary: Colors.blue,
      primaryVariant: Colors.blueAccent,
      secondary: Colors.pink,
      secondaryVariant: Colors.pinkAccent,
      background: Colors.white,
      surface: Colors.white70,
      cardBack: Colors.green,
      boardPrimary: Colors.orange,
      boardSecondary: Colors.yellow,
      accentLight: Colors.white,
      accentDark: Colors.black,
    );

    const darkColors = ThemeColors(
      primary: Colors.black,
      primaryVariant: Colors.black87,
      secondary: Colors.deepPurple,
      secondaryVariant: Colors.deepPurpleAccent,
      background: Colors.black,
      surface: Colors.black54,
      cardBack: Colors.grey,
      boardPrimary: Colors.blueGrey,
      boardSecondary: Colors.grey,
      accentLight: Colors.white,
      accentDark: Colors.black,
    );

    test('bright backgrounds select light theme with dark text', () {
      const theme = CribbageTheme(
        type: ThemeType.spring,
        name: 'Bright',
        colors: brightColors,
        icon: '🌼',
      );
      final data = theme.toThemeData();
      expect(data.brightness, Brightness.light);
      expect(data.colorScheme.background, equals(brightColors.background));
      expect(data.colorScheme.onBackground, Colors.black);
    });

    test('dark backgrounds select dark theme with light text', () {
      const theme = CribbageTheme(
        type: ThemeType.winter,
        name: 'Dark',
        colors: darkColors,
        icon: '❄️',
      );
      final data = theme.toThemeData();
      expect(data.brightness, Brightness.dark);
      expect(data.colorScheme.background, equals(darkColors.background));
      expect(data.colorScheme.onBackground, Colors.white);
      expect(data.cardTheme.color, equals(darkColors.surface));
    });
  });
}
