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

    test('deck contains all 4 suits', () {
      final deck = createDeck();
      expect(deck.where((c) => c.suit == Suit.hearts).length, 13);
      expect(deck.where((c) => c.suit == Suit.diamonds).length, 13);
      expect(deck.where((c) => c.suit == Suit.clubs).length, 13);
      expect(deck.where((c) => c.suit == Suit.spades).length, 13);
    });

    test('deck contains all 13 ranks', () {
      final deck = createDeck();
      for (final rank in Rank.values) {
        expect(deck.where((c) => c.rank == rank).length, 4);
      }
    });
  });

  group('Card equality and hashCode', () {
    test('cards with same rank and suit are equal', () {
      const card1 = PlayingCard(rank: Rank.seven, suit: Suit.hearts);
      const card2 = PlayingCard(rank: Rank.seven, suit: Suit.hearts);
      expect(card1, equals(card2));
      expect(card1.hashCode, equals(card2.hashCode));
    });

    test('cards with different ranks are not equal', () {
      const card1 = PlayingCard(rank: Rank.seven, suit: Suit.hearts);
      const card2 = PlayingCard(rank: Rank.eight, suit: Suit.hearts);
      expect(card1, isNot(equals(card2)));
    });

    test('cards with different suits are not equal', () {
      const card1 = PlayingCard(rank: Rank.seven, suit: Suit.hearts);
      const card2 = PlayingCard(rank: Rank.seven, suit: Suit.clubs);
      expect(card1, isNot(equals(card2)));
    });
  });

  group('Card labels', () {
    test('number cards show rank', () {
      const two = PlayingCard(rank: Rank.two, suit: Suit.hearts);
      const ten = PlayingCard(rank: Rank.ten, suit: Suit.diamonds);
      expect(two.label, '2♥');
      expect(ten.label, '10♦');
    });

    test('face cards show letter', () {
      const jack = PlayingCard(rank: Rank.jack, suit: Suit.clubs);
      const queen = PlayingCard(rank: Rank.queen, suit: Suit.spades);
      const king = PlayingCard(rank: Rank.king, suit: Suit.hearts);
      expect(jack.label, 'J♣');
      expect(queen.label, 'Q♠');
      expect(king.label, 'K♥');
    });

    test('ace shows A', () {
      const ace = PlayingCard(rank: Rank.ace, suit: Suit.diamonds);
      expect(ace.label, 'A♦');
    });
  });

  group('Card values', () {
    test('number cards have face value', () {
      expect(const PlayingCard(rank: Rank.two, suit: Suit.hearts).value, 2);
      expect(const PlayingCard(rank: Rank.five, suit: Suit.clubs).value, 5);
      expect(const PlayingCard(rank: Rank.nine, suit: Suit.diamonds).value, 9);
    });

    test('ten has value 10', () {
      expect(const PlayingCard(rank: Rank.ten, suit: Suit.spades).value, 10);
    });

    test('all face cards have value 10', () {
      expect(const PlayingCard(rank: Rank.jack, suit: Suit.hearts).value, 10);
      expect(const PlayingCard(rank: Rank.queen, suit: Suit.clubs).value, 10);
      expect(const PlayingCard(rank: Rank.king, suit: Suit.diamonds).value, 10);
    });

    test('ace has value 1', () {
      expect(const PlayingCard(rank: Rank.ace, suit: Suit.spades).value, 1);
    });
  });

  test('toString returns label', () {
    const card = PlayingCard(rank: Rank.king, suit: Suit.hearts);
    expect(card.toString(), 'K♥');
  });

  test('encode produces parseable string', () {
    const card = PlayingCard(rank: Rank.five, suit: Suit.clubs);
    final encoded = card.encode();
    expect(encoded, contains('|'));
    final parts = encoded.split('|');
    expect(parts.length, 2);
    expect(int.tryParse(parts[0]), isNotNull);
    expect(int.tryParse(parts[1]), isNotNull);
  });
}
