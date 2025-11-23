import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/services/settings_repository.dart';

void main() {
  group('SettingsRepository', () {
    late SettingsRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = SettingsRepository();
    });

    test('loadSettings returns defaults when nothing stored', () async {
      final settings = await repository.loadSettings();
      expect(settings, const GameSettings());
    });

    test('saveSettings persists values for future loads', () async {
      const custom = GameSettings(
        cardSelectionMode: CardSelectionMode.longPress,
        countingMode: CountingMode.manual,
        selectedTheme: ThemeType.halloween,
      );

      await repository.saveSettings(custom);
      final loaded = await repository.loadSettings();

      expect(loaded, custom);
    });
  });
}
