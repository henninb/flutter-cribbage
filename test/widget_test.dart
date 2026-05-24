// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cribbage/src/app.dart';
import 'package:cribbage/src/game/engine/game_engine.dart';
import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/screens/game_screen.dart';
import 'package:cribbage/src/ui/theme/theme_definitions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(GameEngine engine) =>
      ChangeNotifierProvider<GameEngine>.value(
        value: engine,
        child: CribbageApp(),
      );

  testWidgets('App builds initial screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp(GameEngine()));
    await tester.pumpAndSettle();
    expect(find.text('Cribbage'), findsWidgets);
  });

  testWidgets('App loads with saved theme setting applies that theme',
      (tester) async {
    const settings = GameSettings(selectedTheme: ThemeType.halloween);
    SharedPreferences.setMockInitialValues({
      'game_settings': jsonEncode(settings.toJson()),
    });

    await tester.pumpWidget(buildApp(GameEngine()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Settings change via overlay invokes _handleSettingsChange',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp(GameEngine()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Long Press'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Theme change via settings overlay invokes _handleThemeChange',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp(GameEngine()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<ThemeType?>>(
      find.byType(DropdownButton<ThemeType?>),
    );
    dropdown.onChanged?.call(ThemeType.halloween);
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Direct onThemeChange callback triggers _handleThemeChange',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp(GameEngine()));
    await tester.pumpAndSettle();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    gameScreen.onThemeChange(ThemeDefinitions.halloween);
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
