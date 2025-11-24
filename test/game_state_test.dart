import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/logic/deal_utils.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('HandScores', () {
    test('copyWith updates only provided fields', () {
      const initial = HandScores(
        nonDealerScore: 4,
        dealerScore: 6,
        cribScore: 2,
      );

      final copy = initial.copyWith(dealerScore: 10);
      expect(copy.dealerScore, 10);
      expect(copy.nonDealerScore, 4);
      expect(copy.cribScore, 2);
    });
  });

  group('GameState.copyWith', () {
    final starter = const PlayingCard(rank: Rank.king, suit: Suit.spades);
    final pendingReset = PendingResetState(
      pile: const [
        PlayingCard(rank: Rank.five, suit: Suit.hearts),
      ],
      finalCount: 5,
      scoreAwarded: 2,
      message: 'Go!',
    );
    const playerAnimation = ScoreAnimation(points: 4, isPlayer: true, timestamp: 1);
    const opponentAnimation = ScoreAnimation(points: 3, isPlayer: false, timestamp: 2);

    test('supports clearing optional values via flags', () {
      final base = GameState(
        starterCard: starter,
        pendingReset: pendingReset,
        playerScoreAnimation: playerAnimation,
        opponentScoreAnimation: opponentAnimation,
      );

      final updated = base.copyWith(
        playerScore: 12,
        clearStarterCard: true,
        clearPendingReset: true,
        clearPlayerScoreAnimation: true,
        opponentScoreAnimation: const ScoreAnimation(points: 7, isPlayer: false, timestamp: 3),
      );

      expect(updated.playerScore, 12);
      expect(updated.starterCard, isNull);
      expect(updated.pendingReset, isNull);
      expect(updated.playerScoreAnimation, isNull);
      expect(updated.opponentScoreAnimation!.points, 7);
    });

    test('updates collections and references while retaining others', () {
      final base = GameState(
        playerHand: const [
          PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        ],
        selectedCards: const {0},
        peggingPile: const [],
        gameStatus: 'Initial',
      );
      final newHand = const [
        PlayingCard(rank: Rank.two, suit: Suit.diamonds),
        PlayingCard(rank: Rank.three, suit: Suit.spades),
      ];

      final updated = base.copyWith(
        playerHand: newHand,
        selectedCards: {1, 2},
        gameStatus: 'Updated',
      );

      expect(updated.playerHand, newHand);
      expect(updated.selectedCards, {1, 2});
      expect(updated.gameStatus, 'Updated');
      // Unchanged fields should still match base state
      expect(updated.opponentHand, base.opponentHand);
      expect(updated.peggingPile, base.peggingPile);
    });
  });
}
