import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/card.dart';

typedef PeggingMove = ({int index, PlayingCard card});

class OpponentAI {
  const OpponentAI._();

  static List<PlayingCard> chooseCribCards(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    debugPrint(
      '[OPPONENT AI - CRIB] Choosing crib cards from hand of ${hand.length}: ${hand.map((c) => c.label).join(", ")}',
    );
    debugPrint(
      '[OPPONENT AI - CRIB] Position: ${isDealer ? "Dealer" : "Pone"}',
    );
    if (hand.length != 6) {
      debugPrint(
        '[OPPONENT AI - CRIB WARNING] Hand size != 6, taking first 2 cards',
      );
      return hand.take(2).toList();
    }
    final combos = _generateCombinations(hand);
    debugPrint(
      '[OPPONENT AI - CRIB] Evaluating ${combos.length} possible combinations...',
    );
    combos.sort((a, b) {
      final scoreA = _evaluateCribChoice(a.keep, a.discard, isDealer);
      final scoreB = _evaluateCribChoice(b.keep, b.discard, isDealer);
      return scoreB.compareTo(scoreA);
    });
    final bestChoice = combos.firstOrNull;
    final result = bestChoice?.discard ?? hand.take(2).toList();
    debugPrint(
      '[OPPONENT AI - CRIB] Selected discard: ${result.map((c) => c.label).join(", ")}',
    );
    if (bestChoice != null) {
      debugPrint(
        '[OPPONENT AI - CRIB] Keeping: ${bestChoice.keep.map((c) => c.label).join(", ")}',
      );
    }
    return result;
  }

  static PeggingMove? choosePeggingCard({
    required List<PlayingCard> hand,
    required Set<int> playedIndices,
    required int currentCount,
    required List<PlayingCard> peggingPile,
    required int opponentCardsRemaining,
  }) {
    debugPrint(
      '[OPPONENT AI - PEGGING] Choosing pegging card: count=$currentCount, pile=${peggingPile.map((c) => c.label).join(",")}',
    );
    debugPrint(
      '[OPPONENT AI - PEGGING] Hand: ${hand.asMap().entries.where((e) => !playedIndices.contains(e.key)).map((e) => "${e.key}:${e.value.label}").join(", ")}',
    );
    final legalMoves = <PeggingMove>[];
    for (var i = 0; i < hand.length; i++) {
      if (playedIndices.contains(i)) continue;
      final card = hand[i];
      if (currentCount + card.value <= 31) {
        legalMoves.add((index: i, card: card));
      }
    }
    debugPrint('[OPPONENT AI - PEGGING] Legal moves: ${legalMoves.length}');
    if (legalMoves.isEmpty) {
      debugPrint('[OPPONENT AI - PEGGING] No legal moves available');
      return null;
    }
    legalMoves.sort((a, b) {
      final scoreA = _evaluatePeggingMove(
        a.card,
        currentCount,
        peggingPile,
        opponentCardsRemaining,
      );
      final scoreB = _evaluatePeggingMove(
        b.card,
        currentCount,
        peggingPile,
        opponentCardsRemaining,
      );
      return scoreB.compareTo(scoreA);
    });
    debugPrint(
      '[OPPONENT AI - PEGGING] Best move: ${legalMoves.first.card.label} at index ${legalMoves.first.index}',
    );
    return legalMoves.first;
  }

  static List<_CribChoice> _generateCombinations(List<PlayingCard> hand) {
    final combos = <_CribChoice>[];
    for (var i = 0; i < hand.length; i++) {
      for (var j = i + 1; j < hand.length; j++) {
        final discard = [hand[i], hand[j]];
        final keep = hand
            .asMap()
            .entries
            .where((entry) => entry.key != i && entry.key != j)
            .map((entry) => entry.value)
            .toList();
        combos.add(_CribChoice(keep: keep, discard: discard));
      }
    }
    return combos;
  }

  static double _evaluateCribChoice(
    List<PlayingCard> keep,
    List<PlayingCard> discard,
    bool isDealer,
  ) {
    final handValue = _estimateHandValue(keep);
    final cribValue =
        isDealer ? _estimateCribValue(discard) : -_estimateCribValue(discard);

    // Adjust weights based on dealer status
    // As dealer: prioritize hand more (you get crib bonus anyway)
    // As pone: be more defensive about crib
    final handWeight = isDealer ? 3.5 : 4.0;
    final cribWeight = isDealer ? 1.0 : 1.3;

    return handValue * handWeight + cribValue * cribWeight;
  }

  static double _estimateHandValue(List<PlayingCard> cards) {
    var score = 0.0;

    // Count pairs
    var pairCount = 0;
    for (var i = 0; i < cards.length; i++) {
      for (var j = i + 1; j < cards.length; j++) {
        if (cards[i].rank == cards[j].rank) {
          score += 2;
          pairCount++;
        }
      }
    }

    // Bonus for multiple pairs (royal pair or double pair royal)
    if (pairCount >= 2) {
      score += 1.5; // Multiple pairs are more valuable
    }

    // Count fifteens
    final indices = List.generate(cards.length, (index) => index);
    final combos = <List<int>>[];
    for (var size = 1; size <= cards.length; size++) {
      combos.addAll(_combinations(indices, size));
    }
    var fifteenCount = 0;
    for (final combo in combos) {
      final sum = combo.map((i) => cards[i].value).reduce((a, b) => a + b);
      if (sum == 15) {
        score += 2;
        fifteenCount++;
      }
    }

    // Bonus for multiple fifteens
    if (fifteenCount >= 3) {
      score += 1.0;
    }

    // Evaluate runs - longer runs are significantly better
    final runLength = _findBestRun(cards);
    if (runLength >= 3) {
      score += runLength * 1.2; // Bonus multiplier for runs
    }

    // Flush potential (4-card flush)
    final suitCounts = cards.fold<Map<Suit, int>>(<Suit, int>{}, (acc, card) {
      acc.update(card.suit, (value) => value + 1, ifAbsent: () => 1);
      return acc;
    });
    if (suitCounts.values.any((count) => count == 4)) {
      score += 4; // 4-card flush is valuable
    } else if (suitCounts.values.any((count) => count == 3)) {
      score += 0.5; // 3-card flush has potential with starter
    }

    // Fives are very valuable (many ways to make 15)
    score += cards.where((card) => card.rank == Rank.five).length * 1.0;

    // Middle-range cards (4-9) are versatile for making 15s
    score += cards
            .where((card) => card.rank.index >= 3 && card.rank.index <= 8)
            .length *
        0.5;

    // Aces are flexible but less valuable
    score += cards.where((card) => card.rank == Rank.ace).length * 0.3;

    // Having both high and low cards increases versatility
    final hasLow = cards.any((card) => card.value <= 5);
    final hasHigh = cards.any((card) => card.value >= 10);
    if (hasLow && hasHigh) {
      score += 0.8;
    }

    // Penalize hands with too many face cards (limited 15 potential)
    final faceCardCount = cards.where((card) => card.value == 10).length;
    if (faceCardCount >= 3) {
      score -= 1.0;
    }

    return score;
  }

  static double _estimateCribValue(List<PlayingCard> cards) {
    var value = 0.0;

    // Pairs are very good in crib
    if (cards[0].rank == cards[1].rank) {
      value += 5;
    }

    // 15s are excellent
    if (cards[0].value + cards[1].value == 15) {
      value += 4;
    }

    // Fives are the best cards for crib (many ways to make 15)
    value += cards.where((card) => card.rank == Rank.five).length * 3.0;

    // Close ranks mean better chance of runs with starter
    final rankDiff = (cards[0].rank.index - cards[1].rank.index).abs();
    if (rankDiff == 1) {
      value += 2.5; // Adjacent cards are great
    } else if (rankDiff == 2) {
      value += 1.5; // One card away is good
    } else if (rankDiff == 3) {
      value += 0.5; // Two cards away is okay
    }

    // Same suit increases flush potential
    if (cards[0].suit == cards[1].suit) {
      value += 2.0;
    }

    // Cards that sum to 5 or 10 are versatile
    final sum = cards[0].value + cards[1].value;
    if (sum == 5) {
      value += 2.0; // Very versatile
    } else if (sum == 10) {
      value += 1.5; // Good for 15s
    }

    // Two face cards together are weak (hard to make 15s, runs)
    if (cards.every((card) => card.value == 10)) {
      value -= 2.0;
    }

    // Aces and twos are decent for crib
    value += cards
            .where((card) => card.rank == Rank.ace || card.rank == Rank.two)
            .length *
        0.8;

    // Kings and Queens together are bad (no flexibility)
    if (cards.any((card) => card.rank == Rank.king) &&
        cards.any((card) => card.rank == Rank.queen)) {
      value -= 1.5;
    }

    return value;
  }

  static int _findBestRun(List<PlayingCard> cards) {
    final sortedRanks = cards.map((card) => card.rank.index).toList()..sort();
    for (var length = cards.length; length >= 3; length--) {
      for (var i = 0; i <= sortedRanks.length - length; i++) {
        final subset = sortedRanks.sublist(i, i + length);
        var isRun = true;
        for (var j = 0; j < subset.length - 1; j++) {
          if (subset[j + 1] - subset[j] != 1) {
            isRun = false;
            break;
          }
        }
        if (isRun) {
          return length;
        }
      }
    }
    return 0;
  }

  static double _evaluatePeggingMove(
    PlayingCard card,
    int currentCount,
    List<PlayingCard> peggingPile,
    int opponentCardsRemaining,
  ) {
    var score = 0.0;
    final newCount = currentCount + card.value;

    // === OFFENSIVE SCORING ===

    // Making 31 is the best play
    if (newCount == 31) {
      score += 250;
    }

    // Making 15 is excellent
    if (newCount == 15) {
      score += 180;
    }

    // Pairing logic - be smart about it
    if (peggingPile.isNotEmpty && peggingPile.last.rank == card.rank) {
      // First pair is risky early, great late
      if (opponentCardsRemaining <= 2) {
        score += 140; // Safe to pair when opponent has few cards
      } else if (peggingPile.length <= 2) {
        score += 60; // Risky early - opponent might triple
      } else {
        score += 110; // Mid-game pairing is usually okay
      }

      // Triple pair (we make the third of a kind)
      if (peggingPile.length >= 2 &&
          peggingPile[peggingPile.length - 2].rank == card.rank) {
        score += 200; // Triples are worth a lot!
      }
    }

    // Run potential - completing runs is great
    final runPotential = _evaluateRunPotential(card, peggingPile);
    score += runPotential * 100;

    // === DEFENSIVE PLAY ===

    // Avoid dangerous counts that let opponent score
    if (newCount == 5) {
      score -= 80; // Very dangerous - opponent can easily make 15
    } else if (newCount == 10) {
      score -= 70; // Dangerous - face card makes 15, 5 makes 15
    } else if (newCount == 11) {
      score -= 65; // 4 makes 15
    } else if (newCount == 21) {
      score -= 100; // Very dangerous - any face card makes 31
    } else if (newCount == 6) {
      score -= 50; // 9 makes 15
    }

    // Pairing opponent's last card early is risky (they might triple)
    if (peggingPile.isNotEmpty &&
        peggingPile.last.rank == card.rank &&
        peggingPile.length <= 2 &&
        opponentCardsRemaining > 2) {
      score -= 40; // They might have another
    }

    // Don't play a 5 early (too easy for opponent to score)
    if (card.rank == Rank.five && currentCount < 6) {
      score -= 60;
    }

    // === STRATEGIC POSITIONING ===

    // Getting close to 31 without reaching it can be good
    if (newCount >= 27 && newCount <= 30) {
      score += 45; // Good position - hard for opponent to play
    }

    // Playing low cards early keeps options open
    if (currentCount < 10 && card.value <= 4) {
      score += 25;
    }

    // Playing high cards late is generally good
    if (currentCount >= 15 && card.value >= 8) {
      score += 20;
    }

    // Dangerous zone (22-25) - opponent might make 31
    if (newCount >= 22 && newCount <= 25) {
      score -= 35;
    }

    // If opponent has few cards left, play aggressively
    if (opponentCardsRemaining <= 1) {
      score += 35; // We'll likely get last card
    }

    // === CARD VALUE STRATEGY ===

    // Early game: play low, keep high cards for later
    if (currentCount < 12) {
      score += (5 - card.value) * 3;
    }
    // Late game: play high cards when count is high
    else if (currentCount >= 15) {
      score += (card.value - 5) * 2.5;
    }

    // Middle range cards (6-8) are versatile
    if (card.rank.index >= 5 && card.rank.index <= 7) {
      score += 10;
    }

    return score;
  }

  static double _evaluateRunPotential(
    PlayingCard card,
    List<PlayingCard> pile,
  ) {
    if (pile.isEmpty) {
      return 0;
    }
    final newPile = List<PlayingCard>.from(pile)..add(card);
    for (var runLength = min(newPile.length, 7); runLength >= 3; runLength--) {
      final lastCards = newPile.sublist(newPile.length - runLength);
      final ranks = lastCards.map((c) => c.rank.index).toList();
      final distinct = ranks.toSet().toList()..sort();
      if (distinct.length != runLength) {
        continue;
      }
      var isRun = true;
      for (var i = 0; i < distinct.length - 1; i++) {
        if (distinct[i + 1] - distinct[i] != 1) {
          isRun = false;
          break;
        }
      }
      if (isRun) {
        return runLength.toDouble();
      }
    }
    return 0;
  }

  static List<List<int>> _combinations(List<int> items, int n) {
    if (n == 0) {
      return [<int>[]];
    }
    if (items.isEmpty) {
      return [];
    }
    final result = <List<int>>[];
    void generate(int start, List<int> current) {
      if (current.length == n) {
        result.add(List<int>.from(current));
        return;
      }
      for (var i = start; i < items.length; i++) {
        current.add(items[i]);
        generate(i + 1, current);
        current.removeLast();
      }
    }

    generate(0, <int>[]);
    return result;
  }
}

extension<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _CribChoice {
  _CribChoice({required this.keep, required this.discard});

  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
}
