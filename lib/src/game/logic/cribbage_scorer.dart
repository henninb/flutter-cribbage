import 'package:flutter/foundation.dart';

import '../models/card.dart';

class DetailedScoreBreakdown {
  DetailedScoreBreakdown(this.totalScore, this.entries);

  final int totalScore;
  final List<ScoreEntry> entries;
}

class ScoreEntry {
  ScoreEntry(this.cards, this.type, this.points);

  final List<PlayingCard> cards;
  final String type;
  final int points;
}

class PeggingPoints {
  PeggingPoints({
    required this.total,
    this.fifteen = 0,
    this.thirtyOne = 0,
    this.pairPoints = 0,
    this.sameRankCount = 0,
    this.runPoints = 0,
  });

  final int total;
  final int fifteen;
  final int thirtyOne;
  final int pairPoints;
  final int sameRankCount;
  final int runPoints;
}

class CribbageScorer {
  const CribbageScorer._();

  static DetailedScoreBreakdown scoreHandWithBreakdown(
    List<PlayingCard> hand,
    PlayingCard starter,
    bool isCrib,
  ) {
    debugPrint(
        '[SCORER] Scoring ${isCrib ? "crib" : "hand"}: ${hand.map((c) => c.label).join(", ")} + starter: ${starter.label}');
    final allCards = [...hand, starter];
    final entries = <ScoreEntry>[];

    final n = allCards.length;
    for (var mask = 1; mask < 1 << n; mask++) {
      final cardsInCombo = <PlayingCard>[];
      var sum = 0;
      for (var i = 0; i < n; i++) {
        if ((mask & (1 << i)) != 0) {
          cardsInCombo.add(allCards[i]);
          sum += allCards[i].value;
        }
      }
      if (sum == 15) {
        entries.add(ScoreEntry(cardsInCombo, 'Fifteen', 2));
      }
    }

    final rankGroups = <Rank, List<PlayingCard>>{};
    for (final card in allCards) {
      rankGroups.update(card.rank, (value) => [...value, card],
          ifAbsent: () => [card]);
    }
    for (final cards in rankGroups.values) {
      if (cards.length >= 2) {
        for (var i = 0; i < cards.length; i++) {
          for (var j = i + 1; j < cards.length; j++) {
            entries.add(ScoreEntry([cards[i], cards[j]], 'Pair', 2));
          }
        }
      }
    }

    final freq = <int, int>{};
    for (final card in allCards) {
      freq.update(card.rank.index, (value) => value + 1, ifAbsent: () => 1);
    }
    final sortedRanks = freq.keys.toList()..sort();
    var longestRun = 0;
    for (var i = 0; i < sortedRanks.length; i++) {
      var runLength = 1;
      var j = i + 1;
      while (
          j < sortedRanks.length && sortedRanks[j] == sortedRanks[j - 1] + 1) {
        runLength++;
        j++;
      }
      if (runLength >= 3) {
        longestRun = runLength > longestRun ? runLength : longestRun;
      }
    }

    if (longestRun >= 3) {
      var i = 0;
      while (i < sortedRanks.length) {
        var runLength = 1;
        var runRanks = <int>[sortedRanks[i]];
        var j = i + 1;
        while (j < sortedRanks.length &&
            sortedRanks[j] == sortedRanks[j - 1] + 1) {
          runLength++;
          runRanks.add(sortedRanks[j]);
          j++;
        }
        if (runLength == longestRun) {
          final cardsPerRank = runRanks
              .map((rank) =>
                  allCards.where((card) => card.rank.index == rank).toList())
              .toList();
          final combinations = _generateRunCombinations(cardsPerRank);
          for (final combo in combinations) {
            entries.add(ScoreEntry(combo, 'Sequence', runLength));
          }
        }
        i = j;
      }
    }

    if (hand.isNotEmpty) {
      final suit = hand.first.suit;
      final isFlush = hand.every((card) => card.suit == suit);
      if (isFlush) {
        if (!isCrib) {
          if (starter.suit == suit) {
            entries.add(ScoreEntry(allCards, 'Flush', 5));
          } else {
            entries.add(ScoreEntry(hand, 'Flush', 4));
          }
        } else if (allCards.every((card) => card.suit == suit)) {
          entries.add(ScoreEntry(allCards, 'Crib Flush', 5));
        }
      }
    }

    final nobsCard = hand.where(
      (card) => card.rank == Rank.jack && card.suit == starter.suit,
    );
    if (nobsCard.isNotEmpty) {
      entries.add(ScoreEntry([nobsCard.first, starter], 'His Nobs', 1));
    }

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.points);
    debugPrint(
        '[SCORER] Total score: $total from ${entries.length} scoring combinations');
    if (entries.isNotEmpty) {
      for (final entry in entries) {
        debugPrint(
            '[SCORER]   ${entry.type}: ${entry.cards.map((c) => c.label).join(",")} = ${entry.points}');
      }
    }
    return DetailedScoreBreakdown(total, entries);
  }

  static PeggingPoints pointsForPile(List<PlayingCard> pile, int newCount) {
    debugPrint(
        '[PEGGING SCORER] Evaluating pile: ${pile.map((c) => c.label).join(", ")} | Count: $newCount');
    var total = 0;
    var fifteen = 0;
    var thirtyOne = 0;
    var pairPoints = 0;
    var sameRankCount = 0;
    var runPoints = 0;

    if (newCount == 15) {
      fifteen = 2;
      total += 2;
      debugPrint('[PEGGING SCORER]   15 for 2 points');
    }
    if (newCount == 31) {
      thirtyOne = 2;
      total += 2;
      debugPrint('[PEGGING SCORER]   31 for 2 points');
    }

    if (pile.isNotEmpty) {
      final tailRank = pile.last.rank;
      sameRankCount = 1;
      for (var i = pile.length - 2; i >= 0; i--) {
        if (pile[i].rank == tailRank) {
          sameRankCount++;
        } else {
          break;
        }
      }
      switch (sameRankCount) {
        case 2:
          pairPoints = 2;
          total += 2;
          debugPrint('[PEGGING SCORER]   Pair for 2 points');
          break;
        case 3:
          pairPoints = 6;
          total += 6;
          debugPrint('[PEGGING SCORER]   Pair royal (3-of-kind) for 6 points');
          break;
        case 4:
          pairPoints = 12;
          total += 12;
          debugPrint(
              '[PEGGING SCORER]   Double pair royal (4-of-kind) for 12 points');
          break;
        default:
          break;
      }
    }

    for (var runLength = pile.length; runLength >= 3; runLength--) {
      final window = pile.sublist(pile.length - runLength);
      final ranks = window.map((card) => card.rank.index).toList();
      final distinct = ranks.toSet().toList()..sort();
      if (distinct.length != runLength) {
        continue;
      }
      var consecutive = true;
      for (var i = 0; i < distinct.length - 1; i++) {
        if (distinct[i + 1] - distinct[i] != 1) {
          consecutive = false;
          break;
        }
      }
      if (consecutive) {
        runPoints = runLength;
        total += runPoints;
        debugPrint(
            '[PEGGING SCORER]   Run of $runLength for $runLength points');
        break;
      }
    }

    debugPrint('[PEGGING SCORER] Total pegging points: $total');
    return PeggingPoints(
      total: total,
      fifteen: fifteen,
      thirtyOne: thirtyOne,
      pairPoints: pairPoints,
      sameRankCount: sameRankCount,
      runPoints: runPoints,
    );
  }

  static List<List<PlayingCard>> _generateRunCombinations(
      List<List<PlayingCard>> groups) {
    if (groups.isEmpty) {
      return [<PlayingCard>[]];
    }
    List<List<PlayingCard>> helper(int index) {
      if (index >= groups.length) {
        return [<PlayingCard>[]];
      }
      final tails = helper(index + 1);
      final combos = <List<PlayingCard>>[];
      for (final card in groups[index]) {
        for (final tail in tails) {
          combos.add([card, ...tail]);
        }
      }
      return combos;
    }

    return helper(0)
        .where((combo) => combo.length == groups.length)
        .map((combo) => combo.toList())
        .toList();
  }
}
