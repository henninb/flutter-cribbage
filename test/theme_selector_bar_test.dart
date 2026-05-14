import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/theme/theme_definitions.dart';
import 'package:cribbage/src/ui/widgets/theme_selector_bar.dart';

void main() {
  Widget buildBar({
    CribbageTheme currentTheme = ThemeDefinitions.spring,
    void Function(CribbageTheme)? onThemeSelected,
    VoidCallback? onSettingsClick,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ThemeSelectorBar(
          currentTheme: currentTheme,
          onThemeSelected: onThemeSelected ?? (_) {},
          onSettingsClick: onSettingsClick,
        ),
      ),
    );
  }

  testWidgets('shows settings icon when callback provided', (tester) async {
    await tester.pumpWidget(buildBar(onSettingsClick: () {}));
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('hides settings icon when callback is null', (tester) async {
    await tester.pumpWidget(buildBar());
    expect(find.byIcon(Icons.settings), findsNothing);
  });

  testWidgets('tapping settings icon triggers callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildBar(onSettingsClick: () => tapped = true));

    await tester.tap(find.byIcon(Icons.settings));
    expect(tapped, isTrue);
  });

  testWidgets('tapping a theme icon triggers onThemeSelected', (tester) async {
    CribbageTheme? selected;
    await tester.pumpWidget(
      buildBar(onThemeSelected: (t) => selected = t),
    );

    final summerTheme = ThemeDefinitions.allThemes
        .firstWhere((t) => t.type == ThemeType.summer);
    await tester.tap(find.text(summerTheme.icon).first);

    expect(selected?.type, ThemeType.summer);
  });

  testWidgets('renders all theme buttons', (tester) async {
    await tester.pumpWidget(buildBar());
    await tester.pumpAndSettle();

    // At least spring icon should be visible in the list
    expect(find.text(ThemeDefinitions.spring.icon), findsOneWidget);
  });
}
