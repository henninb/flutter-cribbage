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

  group('OpponentAI.chooseCribIndices', () {
    List<PlayingCard> richHand() => [
          const PlayingCard(rank: Rank.five, suit: Suit.hearts),
          const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
          const PlayingCard(rank: Rank.king, suit: Suit.clubs),
          const PlayingCard(rank: Rank.queen, suit: Suit.hearts),
          const PlayingCard(rank: Rank.nine, suit: Suit.clubs),
          const PlayingCard(rank: Rank.six, suit: Suit.spades),
        ];

    test('returns 2 valid indices for a standard hand', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 60,
        opponentScore: 60,
      );
      expect(indices, hasLength(2));
      expect(indices.every((i) => i >= 0 && i < 6), isTrue);
    });

    test('returns empty list when hand has fewer than 6 cards', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: const [PlayingCard(rank: Rank.five, suit: Suit.hearts)],
        isDealer: false,
        playerScore: 60,
        opponentScore: 60,
      );
      expect(indices, isEmpty);
    });

    test('both players near end game as pone applies endgame weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 108,
        opponentScore: 107,
      );
      expect(indices, hasLength(2));
    });

    test('both players near end game as dealer applies endgame weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: true,
        playerScore: 108,
        opponentScore: 107,
      );
      expect(indices, hasLength(2));
    });

    test('opponent near end game as pone adjusts defensive weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 50,
        opponentScore: 108,
      );
      expect(indices, hasLength(2));
    });

    test('opponent near end game as dealer adjusts crib weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: true,
        playerScore: 50,
        opponentScore: 108,
      );
      expect(indices, hasLength(2));
    });

    test('player within 20 of win as pone adds proximity weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 103,
        opponentScore: 50,
      );
      expect(indices, hasLength(2));
    });

    test('player within 20 of win as dealer adds proximity weights', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: true,
        playerScore: 103,
        opponentScore: 50,
      );
      expect(indices, hasLength(2));
    });

    test('conservative profile as pone adds crib defense weight', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 75,
        opponentScore: 55,
      );
      expect(indices, hasLength(2));
    });

    test('player in proximity range 16-30 from win as pone adds bonus', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: false,
        playerScore: 96,
        opponentScore: 50,
      );
      expect(indices, hasLength(2));
    });

    test('desperate risk profile as dealer applies handWeight boost', () {
      final indices = OpponentAI.chooseCribIndices(
        hand: richHand(),
        isDealer: true,
        playerScore: 30,
        opponentScore: 95,
      );
      expect(indices, hasLength(2));
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

    test('pair with few opponent cards remaining scores aggressively', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
      ];
      final hand = [
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.two, suit: Suit.spades),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 7,
        peggingPile: pile,
        opponentCardsRemaining: 2,
      );
      expect(move, isNotNull);
      expect(move!.card.rank, Rank.seven);
    });

    test('pair in long pile with many opponents uses else branch', () {
      final pile = [
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.seven, suit: Suit.diamonds),
      ];
      final hand = [
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.ace, suit: Suit.spades),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 12,
        peggingPile: pile,
        opponentCardsRemaining: 4,
      );
      expect(move, isNotNull);
    });

    test('triple scoring when pile has two matching rank cards', () {
      // count=7 so playing a seven makes 14 (no 15/21 penalty)
      // ace makes 8 (low bonus only), triple bonus makes seven win
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
        const PlayingCard(rank: Rank.seven, suit: Suit.diamonds),
      ];
      final hand = [
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.ace, suit: Suit.spades),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 7,
        peggingPile: pile,
        opponentCardsRemaining: 3,
      );
      expect(move, isNotNull);
      expect(move!.card.rank, Rank.seven);
    });

    test('only legal move makes count 11', () {
      final hand = [
        const PlayingCard(rank: Rank.two, suit: Suit.clubs),
        const PlayingCard(rank: Rank.king, suit: Suit.spades),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {1},
        currentCount: 9,
        peggingPile: const [],
        opponentCardsRemaining: 3,
      );
      expect(move, isNotNull);
      expect(move!.card.rank, Rank.two);
    });

    test('only legal move makes count 21', () {
      final hand = [
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 20,
        peggingPile: const [],
        opponentCardsRemaining: 3,
      );
      expect(move, isNotNull);
      expect(move!.card.rank, Rank.ace);
    });

    test('high value card when count is at least 15', () {
      final hand = [
        const PlayingCard(rank: Rank.eight, suit: Suit.hearts),
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 15,
        peggingPile: const [],
        opponentCardsRemaining: 3,
      );
      expect(move, isNotNull);
    });

    test('bonus applied when opponent has exactly one card remaining', () {
      final hand = [
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        const PlayingCard(rank: Rank.two, suit: Suit.spades),
      ];
      final move = OpponentAI.choosePeggingCard(
        hand: hand,
        playedIndices: {},
        currentCount: 5,
        peggingPile: const [],
        opponentCardsRemaining: 1,
      );
      expect(move, isNotNull);
    });
  });
}
