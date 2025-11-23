import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_engine.dart';
import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/screens/game_screen.dart';
import 'package:cribbage/src/ui/theme/theme_definitions.dart';

void main() {
  GameScreen _buildScreen({
    required GameEngine engine,
    GameSettings settings = const GameSettings(),
    required void Function(GameSettings) onSettingsChange,
  }) {
    return GameScreen(
      engine: engine,
      currentTheme: ThemeDefinitions.spring,
      onThemeChange: (_) {},
      currentSettings: settings,
      onSettingsChange: onSettingsChange,
    );
  }

  testWidgets('GameScreen toggles settings overlay via AppBar action', (tester) async {
    final engine = GameEngine();

    await tester.pumpWidget(
      MaterialApp(
        home: _buildScreen(
          engine: engine,
          onSettingsChange: (_) {},
        ),
      ),
    );

    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('changing theme in settings overlay invokes callback', (tester) async {
    final engine = GameEngine();
    GameSettings? updated;

    await tester.pumpWidget(
      MaterialApp(
        home: _buildScreen(
          engine: engine,
          onSettingsChange: (value) => updated = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final dropdownFinder = find.byType(DropdownButton<ThemeType?>);
    final dropdown = tester.widget<DropdownButton<ThemeType?>>(dropdownFinder);
    dropdown.onChanged?.call(ThemeType.halloween);
    await tester.pump();

    expect(updated?.selectedTheme, ThemeType.halloween);
  });

  testWidgets('changing card selection mode triggers callback', (tester) async {
    final engine = GameEngine();
    GameSettings? updated;

    await tester.pumpWidget(
      MaterialApp(
        home: _buildScreen(
          engine: engine,
          onSettingsChange: (value) => updated = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Long Press'));
    await tester.pump();

    expect(updated?.cardSelectionMode, CardSelectionMode.longPress);
  });
}
