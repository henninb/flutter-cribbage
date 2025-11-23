import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/deal_utils.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('dealSixToEach', () {
    final deck = _orderedDeck();

    test('player dealer causes opponent to draw first each round', () {
      final result = dealSixToEach(deck, true);

      expect(result.playerHand.length, 6);
      expect(result.opponentHand.length, 6);
      expect(result.remainingDeck.length, deck.length - 12);

      // When player is dealer, opponent gets cards at even indexes (0-based)
      expect(result.opponentHand.first, deck[0]);
      expect(result.playerHand.first, deck[1]);
      expect(result.opponentHand[1], deck[2]);
      expect(result.playerHand[1], deck[3]);
    });

    test('opponent dealer lets player draw first', () {
      final result = dealSixToEach(deck, false);

      expect(result.playerHand.first, deck[0]);
      expect(result.opponentHand.first, deck[1]);
      expect(result.playerHand, hasLength(6));
      expect(result.opponentHand, hasLength(6));

      final expectedRemaining = deck.sublist(12);
      expect(result.remainingDeck, expectedRemaining);
    });
  });

  group('dealerFromCut', () {
    test('returns null on tie', () {
      final player = const PlayingCard(rank: Rank.five, suit: Suit.hearts);
      final opponent = const PlayingCard(rank: Rank.five, suit: Suit.clubs);
      expect(dealerFromCut(player, opponent), isNull);
    });

    test('lower rank becomes dealer', () {
      final player = const PlayingCard(rank: Rank.four, suit: Suit.spades);
      final opponent = const PlayingCard(rank: Rank.jack, suit: Suit.spades);
      expect(dealerFromCut(player, opponent), Player.player);
    });

    test('higher rank makes opponent dealer', () {
      final player = const PlayingCard(rank: Rank.king, suit: Suit.spades);
      final opponent = const PlayingCard(rank: Rank.two, suit: Suit.hearts);
      expect(dealerFromCut(player, opponent), Player.opponent);
    });
  });
}

List<PlayingCard> _orderedDeck() {
  return const [
    PlayingCard(rank: Rank.ace, suit: Suit.clubs),
    PlayingCard(rank: Rank.two, suit: Suit.clubs),
    PlayingCard(rank: Rank.three, suit: Suit.clubs),
    PlayingCard(rank: Rank.four, suit: Suit.clubs),
    PlayingCard(rank: Rank.five, suit: Suit.clubs),
    PlayingCard(rank: Rank.six, suit: Suit.clubs),
    PlayingCard(rank: Rank.seven, suit: Suit.clubs),
    PlayingCard(rank: Rank.eight, suit: Suit.clubs),
    PlayingCard(rank: Rank.nine, suit: Suit.clubs),
    PlayingCard(rank: Rank.ten, suit: Suit.clubs),
    PlayingCard(rank: Rank.jack, suit: Suit.clubs),
    PlayingCard(rank: Rank.queen, suit: Suit.clubs),
    PlayingCard(rank: Rank.king, suit: Suit.clubs),
    PlayingCard(rank: Rank.ace, suit: Suit.spades),
    PlayingCard(rank: Rank.two, suit: Suit.spades),
    PlayingCard(rank: Rank.three, suit: Suit.spades),
  ];
}
