import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';

void main() {
  group('GameSettings', () {
    test('copyWith updates requested fields and can clear theme', () {
      const base = GameSettings(
        cardSelectionMode: CardSelectionMode.tap,
        countingMode: CountingMode.automatic,
        selectedTheme: ThemeType.halloween,
      );

      final updated = base.copyWith(
        cardSelectionMode: CardSelectionMode.longPress,
        countingMode: CountingMode.manual,
        clearSelectedTheme: true,
      );

      expect(updated.cardSelectionMode, CardSelectionMode.longPress);
      expect(updated.countingMode, CountingMode.manual);
      expect(updated.selectedTheme, isNull);
    });

    test('toJson and fromJson round-trip unknown values safely', () {
      const custom = GameSettings(
        cardSelectionMode: CardSelectionMode.drag,
        countingMode: CountingMode.manual,
        selectedTheme: ThemeType.summer,
      );
      final json = custom.toJson();
      final rehydrated = GameSettings.fromJson(json);
      expect(rehydrated, custom);

      final fallback = GameSettings.fromJson({
        'cardSelectionMode': 'unknown',
        'countingMode': 'invalid',
        'selectedTheme': '???',
      });
      expect(fallback.cardSelectionMode, CardSelectionMode.tap);
      expect(fallback.countingMode, CountingMode.automatic);
      expect(fallback.selectedTheme, ThemeType.spring);
    });

    test('equality compares all fields', () {
      const a = GameSettings(
        cardSelectionMode: CardSelectionMode.tap,
        countingMode: CountingMode.automatic,
        selectedTheme: ThemeType.winter,
      );
      const b = GameSettings(
        cardSelectionMode: CardSelectionMode.tap,
        countingMode: CountingMode.automatic,
        selectedTheme: ThemeType.winter,
      );
      const c = GameSettings(
        cardSelectionMode: CardSelectionMode.longPress,
        countingMode: CountingMode.automatic,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });
  });
}
