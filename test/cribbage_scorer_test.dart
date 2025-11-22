import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/cribbage_scorer.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('CribbageScorer', () {
    test('scores fifteens, pairs and runs correctly', () {
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
      ];
      const starter = PlayingCard(rank: Rank.five, suit: Suit.spades);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      expect(breakdown.totalScore, 20);
      expect(breakdown.entries.where((e) => e.type == 'Fifteen').length, greaterThan(0));
    });

    test('pegging scorer detects pairs and runs', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.spades),
        const PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.nine, suit: Suit.hearts),
      ];
      final points = CribbageScorer.pointsForPile(pile, 24);
      expect(points.runPoints, 3);
      expect(points.total, 3);
    });
  });
}
