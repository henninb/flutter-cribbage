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
  });
}
