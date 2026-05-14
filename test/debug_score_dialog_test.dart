import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_engine.dart';
import 'package:cribbage/src/ui/widgets/debug_score_dialog.dart';

void main() {
  Widget buildDialog({
    int playerScore = 10,
    int opponentScore = 20,
  }) {
    final engine = GameEngine();
    return MaterialApp(
      home: Scaffold(
        body: DebugScoreDialog(
          engine: engine,
          currentPlayerScore: playerScore,
          currentOpponentScore: opponentScore,
        ),
      ),
    );
  }

  testWidgets('renders debug title', (tester) async {
    await tester.pumpWidget(buildDialog());
    expect(find.text('Debug Score Adjuster'), findsOneWidget);
  });

  testWidgets('renders initial player score', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 15));
    // Score display appears in both player and opponent adjusters
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('renders initial opponent score', (tester) async {
    await tester.pumpWidget(buildDialog(opponentScore: 30));
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('+1 button increments player score', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 10));

    final addButtons = find.byTooltip('+1');
    // First +1 button is for player
    await tester.tap(addButtons.first);
    await tester.pump();

    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('-1 button decrements player score', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 10));

    final removeButtons = find.byTooltip('-1');
    await tester.tap(removeButtons.first);
    await tester.pump();

    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('+5 button increments player score by 5', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 10));

    final fastForwardButtons = find.byTooltip('+5');
    await tester.tap(fastForwardButtons.first);
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('-5 button decrements player score by 5', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 10));

    final rewindButtons = find.byTooltip('-5');
    await tester.tap(rewindButtons.first);
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('decrement button disabled when score is 0', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 0, opponentScore: 0));

    final decrementButtons = tester.widgetList<IconButton>(
      find.ancestor(
        of: find.byTooltip('-1'),
        matching: find.byType(IconButton),
      ),
    );

    for (final btn in decrementButtons) {
      expect(btn.onPressed, isNull);
    }
  });

  testWidgets('increment button disabled when score is 121', (tester) async {
    await tester.pumpWidget(
      buildDialog(playerScore: 121, opponentScore: 121),
    );

    final incrementButtons = tester.widgetList<IconButton>(
      find.ancestor(
        of: find.byTooltip('+1'),
        matching: find.byType(IconButton),
      ),
    );

    for (final btn in incrementButtons) {
      expect(btn.onPressed, isNull);
    }
  });

  testWidgets('score is clamped at 121 on +5', (tester) async {
    await tester.pumpWidget(buildDialog(playerScore: 119));

    await tester.tap(find.byTooltip('+5').first);
    await tester.pump();

    expect(find.text('121'), findsWidgets);
  });

  testWidgets('Cancel button closes dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DebugScoreDialog(
                  engine: GameEngine(),
                  currentPlayerScore: 10,
                  currentOpponentScore: 20,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Debug Score Adjuster'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Debug Score Adjuster'), findsNothing);
  });

  testWidgets('Apply button closes dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DebugScoreDialog(
                  engine: GameEngine(),
                  currentPlayerScore: 10,
                  currentOpponentScore: 20,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Debug Score Adjuster'), findsNothing);
  });
}
