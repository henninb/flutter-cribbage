import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/ui/widgets/action_bar.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required GameState state,
    required VoidCallback onStartGame,
    required VoidCallback onCutForDealer,
    required VoidCallback onDeal,
    required VoidCallback onConfirmCrib,
    required VoidCallback onGo,
    required VoidCallback onStartCounting,
    required VoidCallback onCountingAccept,
    required VoidCallback onAdvise,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionBar(
            state: state,
            onStartGame: onStartGame,
            onCutForDealer: onCutForDealer,
            onDeal: onDeal,
            onConfirmCrib: onConfirmCrib,
            onGo: onGo,
            onStartCounting: onStartCounting,
            onCountingAccept: onCountingAccept,
            onAdvise: onAdvise,
          ),
        ),
      ),
    );
  }

  testWidgets('shows Start New Game before game begins', (tester) async {
    var started = false;
    await pumpBar(
      tester,
      state: const GameState(),
      onStartGame: () => started = true,
      onCutForDealer: () {},
      onDeal: () {},
      onConfirmCrib: () {},
      onGo: () {},
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('Start New Game'));
    expect(started, isTrue);
  });

  testWidgets('shows Cut Again button when there is a tie', (tester) async {
    var cut = false;
    await pumpBar(
      tester,
      state: GameState(
        gameStarted: true,
        currentPhase: GamePhase.cutForDealer,
        playerHasSelectedCutCard: true,
        cutPlayerCard: const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        cutOpponentCard: const PlayingCard(rank: Rank.five, suit: Suit.clubs),
      ),
      onStartGame: () {},
      onCutForDealer: () => cut = true,
      onDeal: () {},
      onConfirmCrib: () {},
      onGo: () {},
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('Cut Again'));
    expect(cut, isTrue);
  });

  testWidgets('dealing phase shows deal and end game buttons', (tester) async {
    var dealt = false;
    var ended = false;

    await pumpBar(
      tester,
      state: const GameState(
        gameStarted: true,
        currentPhase: GamePhase.dealing,
      ),
      onStartGame: () => ended = true,
      onCutForDealer: () {},
      onDeal: () => dealt = true,
      onConfirmCrib: () {},
      onGo: () {},
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('Deal Cards'));
    await tester.tap(find.text('End Game'));

    expect(dealt, isTrue);
    expect(ended, isTrue);
  });

  testWidgets('crib selection enables confirm button only with two cards', (tester) async {
    var confirmed = false;
    await pumpBar(
      tester,
      state: GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        selectedCards: const {0, 1},
        isPlayerDealer: true,
      ),
      onStartGame: () {},
      onCutForDealer: () {},
      onDeal: () {},
      onConfirmCrib: () => confirmed = true,
      onGo: () {},
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    final button = find.widgetWithText(FilledButton, "Your Crib");
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    expect(confirmed, isTrue);
  });

  testWidgets('pegging phase shows Go button when player cannot play', (tester) async {
    var went = false;
    await pumpBar(
      tester,
      state: GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        isPlayerTurn: true,
        playerHand: const [
          PlayingCard(rank: Rank.two, suit: Suit.hearts),
        ],
        peggingCount: 30,
      ),
      onStartGame: () {},
      onCutForDealer: () {},
      onDeal: () {},
      onConfirmCrib: () {},
      onGo: () => went = true,
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('Go'));
    expect(went, isTrue);
  });

  testWidgets('hand counting phase shows Count Hands button', (tester) async {
    var counted = false;
    await pumpBar(
      tester,
      state: const GameState(
        gameStarted: true,
        currentPhase: GamePhase.handCounting,
        isInHandCountingPhase: false,
      ),
      onStartGame: () {},
      onCutForDealer: () {},
      onDeal: () {},
      onConfirmCrib: () {},
      onGo: () {},
      onStartCounting: () => counted = true,
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('Count Hands'));
    expect(counted, isTrue);
  });

  testWidgets('game over state shows New Game button when modal hidden', (tester) async {
    var restarted = false;
    await pumpBar(
      tester,
      state: const GameState(
        gameStarted: true,
        gameOver: true,
        showWinnerModal: false,
      ),
      onStartGame: () => restarted = true,
      onCutForDealer: () {},
      onDeal: () {},
      onConfirmCrib: () {},
      onGo: () {},
      onStartCounting: () {},
      onCountingAccept: () {},
      onAdvise: () {},
    );

    await tester.tap(find.text('New Game'));
    expect(restarted, isTrue);
  });
}
