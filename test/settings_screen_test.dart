import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/screens/settings_screen.dart';

void main() {
  Widget buildScreen({
    GameSettings settings = const GameSettings(),
    void Function(GameSettings)? onSettingsChange,
    VoidCallback? onBackPressed,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 1200)),
        child: SettingsScreen(
          currentSettings: settings,
          onSettingsChange: onSettingsChange ?? (_) {},
          onBackPressed: onBackPressed ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders section headers', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Card Selection'), findsOneWidget);
    expect(find.text('Counting Mode'), findsOneWidget);
  });

  testWidgets('renders all card selection options', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('Long Press'), findsOneWidget);
    expect(find.text('Drag'), findsOneWidget);
  });

  testWidgets('renders all counting mode options', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
  });

  testWidgets('back button triggers onBackPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(buildScreen(onBackPressed: () => pressed = true));

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(pressed, isTrue);
  });

  testWidgets('tapping Long Press card mode triggers callback', (tester) async {
    GameSettings? updated;
    await tester.pumpWidget(
      buildScreen(onSettingsChange: (s) => updated = s),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Long Press'));
    expect(updated?.cardSelectionMode, CardSelectionMode.longPress);
  });

  testWidgets('tapping Drag card mode triggers callback', (tester) async {
    GameSettings? updated;
    await tester.pumpWidget(
      buildScreen(onSettingsChange: (s) => updated = s),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Drag'));
    expect(updated?.cardSelectionMode, CardSelectionMode.drag);
  });

  testWidgets('tapping already-selected mode does not trigger callback',
      (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      buildScreen(
        settings: const GameSettings(cardSelectionMode: CardSelectionMode.tap),
        onSettingsChange: (_) => callCount++,
      ),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Tap'));
    expect(callCount, 0);
  });

  testWidgets('tapping Manual counting mode triggers callback', (tester) async {
    GameSettings? updated;
    await tester.pumpWidget(
      buildScreen(onSettingsChange: (s) => updated = s),
    );

    await tester.tap(find.text('Manual'));
    expect(updated?.countingMode, CountingMode.manual);
  });

  testWidgets('tapping already-selected counting mode does not callback',
      (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      buildScreen(
        settings: const GameSettings(countingMode: CountingMode.automatic),
        onSettingsChange: (_) => callCount++,
      ),
    );

    await tester.tap(find.text('Automatic'));
    expect(callCount, 0);
  });

  testWidgets('selected card mode shows check circle', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        settings:
            const GameSettings(cardSelectionMode: CardSelectionMode.longPress),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('theme dropdown change triggers callback', (tester) async {
    GameSettings? updated;
    await tester.pumpWidget(
      buildScreen(onSettingsChange: (s) => updated = s),
    );

    final dropdownFinder =
        find.byType(DropdownButton<ThemeType?>);
    final dropdown =
        tester.widget<DropdownButton<ThemeType?>>(dropdownFinder);
    dropdown.onChanged?.call(ThemeType.halloween);
    await tester.pump();

    expect(updated?.selectedTheme, ThemeType.halloween);
  });

  testWidgets('theme dropdown null selection clears theme', (tester) async {
    GameSettings? updated;
    await tester.pumpWidget(
      buildScreen(
        settings: const GameSettings(selectedTheme: ThemeType.spring),
        onSettingsChange: (s) => updated = s,
      ),
    );

    final dropdown =
        tester.widget<DropdownButton<ThemeType?>>(
      find.byType(DropdownButton<ThemeType?>),
    );
    dropdown.onChanged?.call(null);
    await tester.pump();

    expect(updated?.selectedTheme, isNull);
  });
}
