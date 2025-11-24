import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/theme/theme_calculator.dart';

void main() {
  group('ThemeCalculator', () {
    test('prefers holiday theme even during overlapping season', () {
      final theme = ThemeCalculator.getCurrentTheme(DateTime(2024, 12, 25));
      expect(theme.type, ThemeType.christmas);
    });

    test('falls back to seasonal theme when no holiday matches', () {
      final theme = ThemeCalculator.getCurrentTheme(DateTime(2024, 4, 10));
      expect(theme.type, ThemeType.spring);
    });

    test('detects nth weekday-based holidays', () {
      // Jan 15, 2024 is the third Monday (MLK Day)
      final theme = ThemeCalculator.getCurrentTheme(DateTime(2024, 1, 15));
      expect(theme.type, ThemeType.mlkDay);
    });

    test('detects last weekday-based holidays', () {
      // May 27, 2024 is the last Monday of May (Memorial Day)
      final theme = ThemeCalculator.getCurrentTheme(DateTime(2024, 5, 27));
      expect(theme.type, ThemeType.memorialDay);
    });

    test('labor day recognized as first monday in september', () {
      final theme = ThemeCalculator.getCurrentTheme(DateTime(2024, 9, 2)); // first Monday
      expect(theme.type, ThemeType.laborDay);
    });

    test('multi-day holiday windows are honored', () {
      final valentines = ThemeCalculator.getCurrentTheme(DateTime(2024, 2, 12));
      expect(valentines.type, ThemeType.valentinesDay);

      final christmas = ThemeCalculator.getCurrentTheme(DateTime(2024, 12, 24));
      expect(christmas.type, ThemeType.christmas);
    });

    test('season boundaries switch on astronomical dates', () {
      expect(ThemeCalculator.getCurrentTheme(DateTime(2024, 3, 19)).type, ThemeType.winter);
      expect(ThemeCalculator.getCurrentTheme(DateTime(2024, 3, 20)).type, ThemeType.spring);
      expect(ThemeCalculator.getCurrentTheme(DateTime(2024, 6, 21)).type, ThemeType.summer);
      expect(ThemeCalculator.getCurrentTheme(DateTime(2024, 9, 22)).type, ThemeType.fall);
      expect(ThemeCalculator.getCurrentTheme(DateTime(2024, 12, 21)).type, ThemeType.winter);
    });
  });
}
