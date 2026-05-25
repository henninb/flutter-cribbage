import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/ui/widgets/playing_card_widget.dart';

void main() {
  const aceOfSpades = PlayingCard(rank: Rank.ace, suit: Suit.spades);
  const tenOfHearts = PlayingCard(rank: Rank.ten, suit: Suit.hearts);
  const kingOfDiamonds = PlayingCard(rank: Rank.king, suit: Suit.diamonds);
  const twoOfClubs = PlayingCard(rank: Rank.two, suit: Suit.clubs);

  Widget buildCard(
    PlayingCard card, {
    bool isSelected = false,
    bool isPlayed = false,
    bool isPlayable = true,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PlayingCardWidget(
          card: card,
          width: 60,
          isSelected: isSelected,
          isPlayed: isPlayed,
          isPlayable: isPlayable,
          onTap: onTap,
        ),
      ),
    );
  }

  group('Rank.label', () {
    test('ace returns A', () => expect(Rank.ace.label, 'A'));
    test('ten returns 10', () => expect(Rank.ten.label, '10'));
    test('king returns K', () => expect(Rank.king.label, 'K'));
    test('two returns 2', () => expect(Rank.two.label, '2'));

    for (final entry in {
      Rank.three: '3',
      Rank.four: '4',
      Rank.five: '5',
      Rank.six: '6',
      Rank.seven: '7',
      Rank.eight: '8',
      Rank.nine: '9',
      Rank.jack: 'J',
      Rank.queen: 'Q',
    }.entries) {
      test('${entry.key} returns ${entry.value}', () {
        expect(entry.key.label, entry.value);
      });
    }
  });

  group('Suit.label', () {
    test('spades returns ♠', () => expect(Suit.spades.label, '♠'));
    test('hearts returns ♥', () => expect(Suit.hearts.label, '♥'));
    test('diamonds returns ♦', () => expect(Suit.diamonds.label, '♦'));
    test('clubs returns ♣', () => expect(Suit.clubs.label, '♣'));
  });

  group('suitColor', () {
    test('hearts is red', () {
      final color = PlayingCardWidget(card: tenOfHearts, width: 60).suitColor;
      expect(color, const Color(0xFFD32F2F));
    });

    test('diamonds is red', () {
      final color =
          PlayingCardWidget(card: kingOfDiamonds, width: 60).suitColor;
      expect(color, const Color(0xFFD32F2F));
    });

    test('spades is black', () {
      final color = PlayingCardWidget(card: aceOfSpades, width: 60).suitColor;
      expect(color, const Color(0xFF212121));
    });

    test('clubs is black', () {
      final color = PlayingCardWidget(card: twoOfClubs, width: 60).suitColor;
      expect(color, const Color(0xFF212121));
    });
  });

  group('widget rendering', () {
    testWidgets('renders rank and suit text', (tester) async {
      await tester.pumpWidget(buildCard(aceOfSpades));
      expect(find.text('A'), findsWidgets);
      expect(find.text('♠'), findsWidgets);
    });

    testWidgets('onTap fires when card is not played', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCard(aceOfSpades, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(PlayingCardWidget));
      expect(tapped, isTrue);
    });

    testWidgets('onTap does not fire when card is played', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCard(aceOfSpades, isPlayed: true, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(PlayingCardWidget));
      expect(tapped, isFalse);
    });

    testWidgets('renders without error when selected', (tester) async {
      await tester.pumpWidget(buildCard(tenOfHearts, isSelected: true));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without error when not playable', (tester) async {
      await tester.pumpWidget(buildCard(twoOfClubs, isPlayable: false));
      expect(tester.takeException(), isNull);
    });
  });

  group('CardBackWidget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardBackWidget(width: 60),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses explicit height when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardBackWidget(width: 60, height: 100),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
