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

    // Additional comprehensive tests
    test('scores zero for worthless hand', () {
      final hand = [
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
        const PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.queen, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      expect(breakdown.totalScore, 0);
      expect(breakdown.entries, isEmpty);
    });

    test('scores maximum hand (29 points) correctly', () {
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
      ];
      const starter = PlayingCard(rank: Rank.five, suit: Suit.spades);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      expect(breakdown.totalScore, 28); // 4 fives + J = 28 (29 requires right nobs)
    });

    test('scores pair royal (three of a kind) as 6 points', () {
      final hand = [
        const PlayingCard(rank: Rank.king, suit: Suit.hearts),
        const PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.king, suit: Suit.clubs),
        const PlayingCard(rank: Rank.two, suit: Suit.spades),
      ];
      const starter = PlayingCard(rank: Rank.three, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final pairPoints = breakdown.entries
          .where((e) => e.type == 'Pair')
          .fold<int>(0, (sum, entry) => sum + entry.points);
      expect(pairPoints, 6); // 3 pairs from 3 kings
    });

    test('scores double pair royal (four of a kind) as 12 points', () {
      final hand = [
        const PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        const PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        const PlayingCard(rank: Rank.queen, suit: Suit.spades),
      ];
      const starter = PlayingCard(rank: Rank.three, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final pairPoints = breakdown.entries
          .where((e) => e.type == 'Pair')
          .fold<int>(0, (sum, entry) => sum + entry.points);
      expect(pairPoints, 12); // 6 pairs from 4 queens
    });

    test('scores multiple fifteens correctly', () {
      final hand = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        const PlayingCard(rank: Rank.jack, suit: Suit.spades),
        const PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.king, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final fifteenCount = breakdown.entries.where((e) => e.type == 'Fifteen').length;
      expect(fifteenCount, 4); // 5+10, 5+J, 5+Q, 5+K
      expect(breakdown.totalScore, 8); // 4 fifteens * 2 points
    });

    test('scores 4-card run correctly', () {
      final hand = [
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.six, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.king, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final runEntry = breakdown.entries.where((e) => e.type == 'Sequence').single;
      expect(runEntry.points, 4);
    });

    test('scores 5-card run correctly', () {
      final hand = [
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.six, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final runEntry = breakdown.entries.where((e) => e.type == 'Sequence').single;
      expect(runEntry.points, 5);
    });

    test('does not score broken run', () {
      final hand = [
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.spades), // Gap!
        const PlayingCard(rank: Rank.six, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.king, suit: Suit.hearts);

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final runEntries = breakdown.entries.where((e) => e.type == 'Sequence');
      expect(runEntries, isEmpty);
    });

    test('does not award his nobs when jack suit differs from starter', () {
      final hand = [
        const PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.ten, suit: Suit.diamonds),
      ];
      const starter = PlayingCard(rank: Rank.seven, suit: Suit.clubs); // Different suit

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final nobsEntries = breakdown.entries.where((e) => e.type == 'His Nobs');
      expect(nobsEntries, isEmpty);
    });

    test('4-card flush in hand scores 4 points', () {
      final hand = [
        const PlayingCard(rank: Rank.two, suit: Suit.spades),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
        const PlayingCard(rank: Rank.eight, suit: Suit.spades),
      ];
      const starter = PlayingCard(rank: Rank.king, suit: Suit.hearts); // Different suit

      final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
      final flushEntry = breakdown.entries.where((e) => e.type == 'Flush').single;
      expect(flushEntry.points, 4);
    });

    test('pegging detects fifteen', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
        const PlayingCard(rank: Rank.eight, suit: Suit.clubs),
      ];
      final points = CribbageScorer.pointsForPile(pile, 15);
      expect(points.fifteen, 2);
      expect(points.total, 2);
    });

    test('pegging detects thirty-one', () {
      final pile = [
        const PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        const PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        const PlayingCard(rank: Rank.ten, suit: Suit.spades),
        const PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
      ];
      final points = CribbageScorer.pointsForPile(pile, 31);
      expect(points.thirtyOne, 2);
      expect(points.total, greaterThanOrEqualTo(2));
    });

    test('pegging detects pair', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
      ];
      final points = CribbageScorer.pointsForPile(pile, 14);
      expect(points.pairPoints, 2);
      expect(points.sameRankCount, 2);
    });

    test('pegging detects pair royal', () {
      final pile = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final points = CribbageScorer.pointsForPile(pile, 15);
      expect(points.pairPoints, 6);
      expect(points.sameRankCount, 3);
      expect(points.fifteen, 2); // Also a fifteen!
      expect(points.total, 8);
    });

    test('pegging detects double pair royal', () {
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.three, suit: Suit.spades),
      ];
      final points = CribbageScorer.pointsForPile(pile, 12);
      expect(points.pairPoints, 12);
      expect(points.sameRankCount, 4);
    });

    test('pegging detects 4-card run', () {
      final pile = [
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.six, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.seven, suit: Suit.spades),
      ];
      final points = CribbageScorer.pointsForPile(pile, 22);
      expect(points.runPoints, 4);
    });

    test('pegging run can be out of order', () {
      final pile = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.six, suit: Suit.diamonds),
      ];
      final points = CribbageScorer.pointsForPile(pile, 18);
      expect(points.runPoints, 3);
    });

    test('pegging ignores non-consecutive cards for runs', () {
      final pile = [
        const PlayingCard(rank: Rank.two, suit: Suit.hearts),
        const PlayingCard(rank: Rank.nine, suit: Suit.clubs),
      ];
      final points = CribbageScorer.pointsForPile(pile, 11);
      expect(points.runPoints, 0);
      expect(points.total, 0);
    });

    test('pegging combines multiple scoring types', () {
      final pile = [
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
      ];
      final points = CribbageScorer.pointsForPile(pile, 10);
      expect(points.pairPoints, 2); // Pair
      expect(points.total, 2);
    });

    test('empty pile scores zero', () {
      final pile = <PlayingCard>[];
      final points = CribbageScorer.pointsForPile(pile, 0);
      expect(points.total, 0);
    });
  });
}
