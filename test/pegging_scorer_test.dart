import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage/src/game/logic/cribbage_scorer.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  group('PeggingScorer - Basic Tests', () {
    test('no points when no fifteen, no 31, no pair, no run', () {
      final pile = [
        const PlayingCard(rank: Rank.two, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 6);
      expect(pts.total, 0);
      expect(pts.fifteen, 0);
      expect(pts.thirtyOne, 0);
      expect(pts.pairPoints, 0);
      expect(pts.runPoints, 0);
    });

    test('run - longest trailing run only', () {
      // Earlier cards (4,5,6) form a run, but the trailing window (5,6,9) does not.
      final pile = [
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
        const PlayingCard(rank: Rank.nine, suit: Suit.diamonds),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 30);
      expect(pts.total, 0);
      expect(pts.runPoints, 0);
    });

    test('duplicates in trailing window break run', () {
      // 3-3-4-4-5: duplicates in trailing window break pegging run
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
        const PlayingCard(rank: Rank.four, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 15);
      expect(pts.runPoints, 0);
      // 15 still scores +2
      expect(pts.fifteen, 2);
    });

    test('pair scores alone when duplicates break run', () {
      // Tail 3-4-5-5: duplicates at tail break run; only pair scores
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final newCount = 3 + 4 + 5 + 5; // 17
      final pts = CribbageScorer.pointsForPile(pile, newCount);
      expect(pts.runPoints, 0);
      expect(pts.pairPoints, 2);
      expect(pts.sameRankCount, 2);
      expect(pts.total, 2);
    });

    test('run of five counts', () {
      final pile = [
        const PlayingCard(rank: Rank.nine, suit: Suit.clubs),
        const PlayingCard(rank: Rank.ten, suit: Suit.hearts),
        const PlayingCard(rank: Rank.jack, suit: Suit.spades),
        const PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.king, suit: Suit.clubs),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 9 + 10 + 10 + 10 + 10);
      expect(pts.runPoints, 5);
      expect(pts.total, 5);
    });

    test('fifteen with pair scores both', () {
      // 1 + 4 + 5 + 5 => last play makes 15 and a pair simultaneously
      final pile = [
        const PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 15);
      expect(pts.total, 4);
      expect(pts.fifteen, 2);
      expect(pts.pairPoints, 2);
      expect(pts.sameRankCount, 2);
      expect(pts.runPoints, 0);
    });

    test('thirty-one with pair scores both', () {
      // 10 + 10 + 1 + 5 + 5 => 31, with last two a pair
      final pile = [
        const PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        const PlayingCard(rank: Rank.king, suit: Suit.hearts),
        const PlayingCard(rank: Rank.ace, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 31);
      expect(pts.total, 4);
      expect(pts.thirtyOne, 2);
      expect(pts.pairPoints, 2);
      expect(pts.sameRankCount, 2);
      expect(pts.runPoints, 0);
    });
  });

  group('PeggingScorer - Run Scenarios', () {
    test('simple 3-card run (7-8-9)', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.spades),
        const PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
        const PlayingCard(rank: Rank.nine, suit: Suit.hearts),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 24);
      expect(pts.runPoints, 3);
      expect(pts.total, 3);
    });

    test('4-card run (3-4-5-6)', () {
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.six, suit: Suit.diamonds),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 18);
      expect(pts.runPoints, 4);
      expect(pts.total, 4);
    });

    test('run out of order (5-3-4)', () {
      final pile = [
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 12);
      expect(pts.runPoints, 3);
      expect(pts.total, 3);
    });

    test('extended run after initial run (2-3-4, then 5)', () {
      // First pile: 2-3-4 (run of 3)
      final pile1 = [
        const PlayingCard(rank: Rank.two, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
      ];
      final pts1 = CribbageScorer.pointsForPile(pile1, 9);
      expect(pts1.runPoints, 3);

      // Extended pile: 2-3-4-5 (run of 4)
      final pile2 = [
        const PlayingCard(rank: Rank.two, suit: Suit.clubs),
        const PlayingCard(rank: Rank.three, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final pts2 = CribbageScorer.pointsForPile(pile2, 14);
      expect(pts2.runPoints, 4);
    });
  });

  group('PeggingScorer - Pair Scenarios', () {
    test('simple pair', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.seven, suit: Suit.hearts),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 14);
      expect(pts.pairPoints, 2);
      expect(pts.sameRankCount, 2);
      expect(pts.total, 2);
    });

    test('three of a kind (triple)', () {
      final pile = [
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 12);
      expect(pts.pairPoints, 6);
      expect(pts.sameRankCount, 3);
      expect(pts.total, 6);
    });

    test('four of a kind', () {
      final pile = [
        const PlayingCard(rank: Rank.five, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.five, suit: Suit.spades),
        const PlayingCard(rank: Rank.five, suit: Suit.diamonds),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 20);
      expect(pts.pairPoints, 12);
      expect(pts.sameRankCount, 4);
      expect(pts.total, 12);
    });

    test('pair interrupted by different card', () {
      final pile = [
        const PlayingCard(rank: Rank.seven, suit: Suit.clubs),
        const PlayingCard(rank: Rank.eight, suit: Suit.hearts),
        const PlayingCard(rank: Rank.seven, suit: Suit.spades),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 22);
      expect(pts.pairPoints, 0); // Not consecutive
      expect(pts.sameRankCount, 1);
    });
  });

  group('PeggingScorer - Complex Combinations', () {
    test('15 and run together', () {
      // 4-5-6 makes 15 and a run of 3
      final pile = [
        const PlayingCard(rank: Rank.four, suit: Suit.clubs),
        const PlayingCard(rank: Rank.five, suit: Suit.hearts),
        const PlayingCard(rank: Rank.six, suit: Suit.spades),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 15);
      expect(pts.fifteen, 2);
      expect(pts.runPoints, 3);
      expect(pts.total, 5);
    });

    test('run and pair cannot occur together', () {
      // If there's a duplicate, it breaks the run in pegging
      final pile = [
        const PlayingCard(rank: Rank.three, suit: Suit.clubs),
        const PlayingCard(rank: Rank.four, suit: Suit.hearts),
        const PlayingCard(rank: Rank.four, suit: Suit.spades),
      ];
      final pts = CribbageScorer.pointsForPile(pile, 11);
      expect(pts.pairPoints, 2);
      expect(pts.runPoints, 0); // Duplicates break run
    });
  });
}
