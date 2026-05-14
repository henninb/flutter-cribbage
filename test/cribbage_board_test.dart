import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/ui/widgets/cribbage_board.dart';

void main() {
  Widget buildBoard({
    int playerScore = 0,
    int opponentScore = 0,
    String playerName = 'You',
    String opponentName = 'Opponent',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CribbageBoard(
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerName: playerName,
          opponentName: opponentName,
        ),
      ),
    );
  }

  testWidgets('renders player name', (tester) async {
    await tester.pumpWidget(buildBoard(playerName: 'Alice'));
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('renders opponent name', (tester) async {
    await tester.pumpWidget(buildBoard(opponentName: 'Bob'));
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('renders with zero scores without error', (tester) async {
    await tester.pumpWidget(buildBoard());
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with mid-game scores without error', (tester) async {
    await tester.pumpWidget(buildBoard(playerScore: 60, opponentScore: 45));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with winning score without error', (tester) async {
    await tester.pumpWidget(buildBoard(playerScore: 121, opponentScore: 89));
    expect(tester.takeException(), isNull);
  });
}
