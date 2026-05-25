import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/logic/cribbage_scorer.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/ui/widgets/hand_counting_dialog.dart';

void main() {
  const playerHand = [
    PlayingCard(rank: Rank.five, suit: Suit.hearts),
    PlayingCard(rank: Rank.five, suit: Suit.diamonds),
    PlayingCard(rank: Rank.five, suit: Suit.clubs),
    PlayingCard(rank: Rank.jack, suit: Suit.spades),
  ];

  const opponentHand = [
    PlayingCard(rank: Rank.ace, suit: Suit.hearts),
    PlayingCard(rank: Rank.two, suit: Suit.clubs),
    PlayingCard(rank: Rank.three, suit: Suit.diamonds),
    PlayingCard(rank: Rank.four, suit: Suit.spades),
  ];

  const cribHand = [
    PlayingCard(rank: Rank.six, suit: Suit.hearts),
    PlayingCard(rank: Rank.seven, suit: Suit.clubs),
    PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
    PlayingCard(rank: Rank.nine, suit: Suit.spades),
  ];

  Widget buildDialog(GameState state) {
    return MaterialApp(
      home: Scaffold(
        body: HandCountingDialog(state: state),
      ),
    );
  }

  testWidgets('returns empty widget when countingPhase is none',
      (tester) async {
    await tester.pumpWidget(
      buildDialog(const GameState(currentPhase: GamePhase.handCounting)),
    );

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('nonDealer phase shows opponent hand title when player is dealer',
      (tester) async {
    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.nonDealer,
          isPlayerDealer: true,
          playerHand: playerHand,
          opponentHand: opponentHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: const HandScores(),
        ),
      ),
    );

    expect(find.textContaining("Bot"), findsWidgets);
  });

  testWidgets(
      'nonDealer phase shows player hand title when player is not dealer',
      (tester) async {
    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.nonDealer,
          isPlayerDealer: false,
          playerHand: playerHand,
          opponentHand: opponentHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: const HandScores(),
        ),
      ),
    );

    expect(find.textContaining("You"), findsWidgets);
  });

  testWidgets('dealer phase shows player hand title when player is dealer',
      (tester) async {
    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.dealer,
          isPlayerDealer: true,
          playerHand: playerHand,
          opponentHand: opponentHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: const HandScores(),
        ),
      ),
    );

    expect(find.textContaining("You"), findsWidgets);
  });

  testWidgets('crib phase shows player crib title when player is dealer',
      (tester) async {
    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.crib,
          isPlayerDealer: true,
          playerHand: playerHand,
          opponentHand: opponentHand,
          cribHand: cribHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: const HandScores(),
        ),
      ),
    );

    expect(find.textContaining("You"), findsWidgets);
    expect(find.textContaining("Crib"), findsWidgets);
  });

  testWidgets('shows No points scored when breakdown is empty', (tester) async {
    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.nonDealer,
          isPlayerDealer: true,
          playerHand: playerHand,
          opponentHand: opponentHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: const HandScores(),
        ),
      ),
    );

    expect(find.text('No points scored'), findsOneWidget);
  });

  testWidgets('shows score breakdown table when entries exist', (tester) async {
    final breakdown = DetailedScoreBreakdown(2, [
      ScoreEntry(
        [
          const PlayingCard(rank: Rank.five, suit: Suit.hearts),
          const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
        ],
        'Pair',
        2,
      ),
    ]);

    await tester.pumpWidget(
      buildDialog(
        GameState(
          currentPhase: GamePhase.handCounting,
          countingPhase: CountingPhase.nonDealer,
          isPlayerDealer: true,
          playerHand: playerHand,
          opponentHand: opponentHand,
          playerName: 'You',
          opponentName: 'Bot',
          handScores: HandScores(nonDealerBreakdown: breakdown),
        ),
      ),
    );

    expect(find.text('Pair'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });
}
