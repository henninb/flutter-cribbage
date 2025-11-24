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
      // 2 for fifteen, 6 for the three pairs, and 9 for the triple run = 17 total
      expect(breakdown.totalScore, 17);
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

    test('flush scoring respects crib rules', () {
      final hand = [
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.six, suit: Suit.hearts),
        const PlayingCard(rank: Rank.nine, suit: Suit.hearts),
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts),
      ];
      const starterHeart = PlayingCard(rank: Rank.two, suit: Suit.hearts);
      const starterClub = PlayingCard(rank: Rank.king, suit: Suit.clubs);

      final regular = CribbageScorer.scoreHandWithBreakdown(hand, starterHeart, false);
      expect(
        regular.entries.where((e) => e.type.contains('Flush')).single.points,
        5,
      );

      final cribNoStarter = CribbageScorer.scoreHandWithBreakdown(hand, starterClub, true);
      expect(cribNoStarter.entries.where((e) => e.type.contains('Flush')), isEmpty);

      final cribAllMatch = CribbageScorer.scoreHandWithBreakdown(hand, starterHeart, true);
      expect(
        cribAllMatch.entries.where((e) => e.type.contains('Flush')).single.points,
        5,
      );
    });

    test('his nobs awards a single point when jack matches starter suit', () {
      final hand = [
        const PlayingCard(rank: Rank.jack, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.ten, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.seven, suit: Suit.clubs);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      expect(
        breakdown.entries.where((e) => e.type == 'His Nobs').single.points,
        1,
      );
    });

    test('duplicate ranks contribute multiple run combinations', () {
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
        const PlayingCard(rank: Rank.six, suit: Suit.clubs),
      ];
      const starter = PlayingCard(rank: Rank.seven, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final runEntries = breakdown.entries.where((e) => e.type == 'Sequence').toList();
      expect(runEntries.length, 4); // 2x5 * 2x6 combinations
      expect(runEntries.every((entry) => entry.points == 3), isTrue);
      final totalRunPoints = runEntries.fold<int>(0, (sum, entry) => sum + entry.points);
      expect(totalRunPoints, 12);
    });
  });
}
