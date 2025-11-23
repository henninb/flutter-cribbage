import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('PlayingCard encoding and values', () {
    test('encode/decode round trip preserves rank and suit', () {
      const original = PlayingCard(rank: Rank.queen, suit: Suit.diamonds);
      final decoded = PlayingCard.decode(original.encode());
      expect(decoded, original);
    });

    test('decode clamps invalid indices into valid enum ranges', () {
      final decoded = PlayingCard.decode('99|99');
      expect(decoded.rank, Rank.king);
      expect(decoded.suit, Suit.spades);
    });

    test('value maps face cards to ten', () {
      const jack = PlayingCard(rank: Rank.jack, suit: Suit.spades);
      const queen = PlayingCard(rank: Rank.queen, suit: Suit.spades);
      const king = PlayingCard(rank: Rank.king, suit: Suit.spades);
      expect(jack.value, 10);
      expect(queen.value, 10);
      expect(king.value, 10);
      expect(const PlayingCard(rank: Rank.ace, suit: Suit.spades).value, 1);
    });

    test('label produces concise rank and suit symbols', () {
      const card = PlayingCard(rank: Rank.ace, suit: Suit.clubs);
      expect(card.label, 'A♣');
    });
  });

  group('Deck creation', () {
    test('createDeck returns 52 unique cards', () {
      final deck = createDeck();
      expect(deck, hasLength(52));
      expect(deck.toSet(), hasLength(52));
    });

    test('createDeck accepts seeded random for deterministic shuffle', () {
      final deckA = createDeck(random: Random(42));
      final deckB = createDeck(random: Random(42));
      expect(deckA, deckB);
    });
  });
}
