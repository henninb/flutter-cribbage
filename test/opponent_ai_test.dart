import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/opponent_ai.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('OpponentAI.chooseCribCards', () {
    test('falls back to first two cards when hand is incomplete', () {
      final hand = [
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.spades),
        const PlayingCard(rank: Rank.four, suit: Suit.diamonds),
      ];

      final discards = OpponentAI.chooseCribCards(hand, true);
      expect(discards, hand.take(2));
    });

    test('dealer favors preserving a four-card flush', () {
      final hand = [
        const PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.ten, suit: Suit.spades),
        const PlayingCard(rank: Rank.king, suit: Suit.clubs),
      ];

      final discards = OpponentAI.chooseCribCards(hand, true);
      expect(discards, [hand[4], hand[5]]);
    });

    test('pone ditches high cards to avoid gifting crib points', () {
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.king, suit: Suit.hearts),
        const PlayingCard(rank: Rank.king, suit: Suit.clubs),
        const PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        const PlayingCard(rank: Rank.jack, suit: Suit.clubs),
      ];

      final discards = OpponentAI.chooseCribCards(hand, false);
      expect(discards, [hand[4], hand[5]]);
    });
  });

  group('OpponentAI.choosePeggingCard', () {
    test('returns null when no legal moves exist', () {
      final hand = [
        const PlayingCard(rank: Rank.king, suit: Suit.hearts),
        const PlayingCard(rank: Rank.queen, suit: Suit.clubs),
      ];

      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 30,
        peggingPile: const [],
        opponentCardsRemaining: 3,
      );

      expect(move, isNull);
    });

    test('prioritizes making thirty-one when possible', () {
      final hand = [
        const PlayingCard(rank: Rank.four, suit: Suit.hearts), // leads to 31
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
      ];

      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 27,
        peggingPile: const [],
        opponentCardsRemaining: 2,
      );

      expect(move, isNotNull);
      expect(move!.card, hand[0]);
      expect(move.index, 0);
    });

    test('completes runs ahead of higher raw value plays', () {
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.diamonds),
      ];
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.spades), // completes run
        const PlayingCard(rank: Rank.ten, suit: Suit.clubs),
      ];

      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 7,
        peggingPile: pile,
        opponentCardsRemaining: 3,
      );

      expect(move, isNotNull);
      expect(move!.card, hand[0]);
    });
  });
}
