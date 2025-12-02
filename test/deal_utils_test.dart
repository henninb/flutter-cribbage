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

    test('ace beats all other cards', () {
      final player = const PlayingCard(rank: Rank.ace, suit: Suit.hearts);
      final opponent = const PlayingCard(rank: Rank.king, suit: Suit.spades);
      expect(dealerFromCut(player, opponent), Player.player);
    });

    test('two beats three and higher', () {
      final player = const PlayingCard(rank: Rank.two, suit: Suit.diamonds);
      final opponent = const PlayingCard(rank: Rank.nine, suit: Suit.clubs);
      expect(dealerFromCut(player, opponent), Player.player);
    });

    test('king loses to all cards except queen and jack', () {
      final player = const PlayingCard(rank: Rank.king, suit: Suit.hearts);
      final opponent = const PlayingCard(rank: Rank.three, suit: Suit.clubs);
      expect(dealerFromCut(player, opponent), Player.opponent);
    });
  });

  group('deal edge cases', () {
    test('deals with empty remaining deck', () {
      final smallDeck = [
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        const PlayingCard(rank: Rank.two, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.six, suit: Suit.clubs),
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.eight, suit: Suit.clubs),
        const PlayingCard(rank: Rank.nine, suit: Suit.clubs),
        const PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        const PlayingCard(rank: Rank.jack, suit: Suit.clubs),
        const PlayingCard(rank: Rank.queen, suit: Suit.clubs),
      ];
      final result = dealSixToEach(smallDeck, true);
      expect(result.remainingDeck, isEmpty);
    });

    test('player hand has no duplicates from opponent hand', () {
      final result = dealSixToEach(_orderedDeck(), true);
      final combined = [...result.playerHand, ...result.opponentHand];
      expect(combined.length, 12);
      expect(combined.toSet().length, 12); // All unique
    });

    test('alternating pattern maintained for full deal', () {
      final result = dealSixToEach(_orderedDeck(), false);
      // Player is not dealer, so player gets first card
      expect(result.playerHand[0], _orderedDeck()[0]);
      expect(result.opponentHand[0], _orderedDeck()[1]);
      expect(result.playerHand[1], _orderedDeck()[2]);
      expect(result.opponentHand[1], _orderedDeck()[3]);
      expect(result.playerHand[2], _orderedDeck()[4]);
      expect(result.opponentHand[2], _orderedDeck()[5]);
    });

    test('remaining deck preserves order', () {
      final result = dealSixToEach(_orderedDeck(), true);
      expect(result.remainingDeck[0], _orderedDeck()[12]);
      expect(result.remainingDeck[1], _orderedDeck()[13]);
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
