import 'dart:math';

import '../models/card.dart';

typedef PeggingMove = ({int index, PlayingCard card});

enum RiskProfile {
  desperate,
  aggressive,
  balanced,
  conservative,
}

class OpponentAI {
  const OpponentAI._();

  /// Chooses two cards for the opponent to discard to the crib.
  static List<PlayingCard> chooseCribCards(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    if (hand.length != 6) {
      return hand.take(2).toList();
    }
    final combos = _generateCombinations(hand);
    final scored = combos
        .map((c) => (combo: c, score: _evaluateCribChoice(c.keep, c.discard, isDealer)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.firstOrNull?.combo.discard ?? hand.take(2).toList();
  }

  /// Returns the indices in [hand] of the two cards the player should discard,
  /// taking the current game score into account.
  static List<int> chooseCribIndices({
    required List<PlayingCard> hand,
    required bool isDealer,
    required int playerScore,
    required int opponentScore,
  }) {
    if (hand.length != 6) return [];
    assert(hand.toSet().length == hand.length, 'Hand contains duplicate cards');

    final combos = _generateCombinations(hand);
    final scored = combos
        .map((c) => (
              combo: c,
              score: _evaluateCribChoiceWithPosition(
                c.keep,
                c.discard,
                isDealer,
                playerScore,
                opponentScore,
              ),
            ),)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final best = scored.firstOrNull?.combo;
    if (best == null) return [];

    final indices = <int>[];
    for (var i = 0; i < hand.length; i++) {
      if (best.discard.contains(hand[i])) {
        indices.add(i);
        if (indices.length == 2) break;
      }
    }
    return indices;
  }

  /// Chooses the best legal pegging card, or null if none is playable.
  static PeggingMove? choosePeggingCard({
    required List<PlayingCard> hand,
    required Set<int> playedIndices,
    required int currentCount,
    required List<PlayingCard> peggingPile,
    required int opponentCardsRemaining,
  }) {
    final legalMoves = <PeggingMove>[];
    for (var i = 0; i < hand.length; i++) {
      if (playedIndices.contains(i)) continue;
      final card = hand[i];
      if (currentCount + card.value <= 31) {
        legalMoves.add((index: i, card: card));
      }
    }
    if (legalMoves.isEmpty) return null;

    final scored = legalMoves
        .map((m) => (
              move: m,
              score: _evaluatePeggingMove(
                m.card,
                currentCount,
                peggingPile,
                opponentCardsRemaining,
              ),
            ),)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.first.move;
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

    final handWeight = isDealer ? 3.5 : 4.0;
    final cribWeight = isDealer ? 1.0 : 1.3;

    return handValue * handWeight + cribValue * cribWeight;
  }

  static double _evaluateCribChoiceWithPosition(
    List<PlayingCard> keep,
    List<PlayingCard> discard,
    bool isDealer,
    int playerScore,
    int opponentScore,
  ) {
    final handValue = _estimateHandValue(keep);
    final rawCribValue = _estimateCribValue(discard);
    final cribDamagePotential = _estimateCribDamagePotential(discard);
    final cribValue =
        isDealer ? rawCribValue : -(rawCribValue + cribDamagePotential);

    final scoreDiff = playerScore - opponentScore;
    final playerDistanceFrom121 = 121 - playerScore;
    final opponentDistanceFrom121 = 121 - opponentScore;

    final riskProfile = _calculateRiskProfile(
      scoreDiff: scoreDiff,
      playerDistanceFrom121: playerDistanceFrom121,
      opponentDistanceFrom121: opponentDistanceFrom121,
      isDealer: isDealer,
    );

    var handWeight = isDealer ? 3.5 : 4.0;
    var cribWeight = isDealer ? 1.0 : 1.3;

    if (playerDistanceFrom121 <= 15 && opponentDistanceFrom121 <= 15) {
      if (!isDealer) {
        handWeight += 2.5;
        cribWeight += 2.0;
      } else {
        handWeight += 1.0;
        cribWeight += 1.5;
      }
    } else if (opponentDistanceFrom121 <= 15) {
      if (!isDealer) {
        handWeight += 1.5;
        cribWeight += 2.5;
      } else {
        handWeight += 0.5;
        cribWeight += 1.0;
      }
    } else if (playerDistanceFrom121 <= 20) {
      if (!isDealer) {
        handWeight += 1.8;
        cribWeight += 1.0;
      } else {
        handWeight += 0.8;
        cribWeight += 1.2;
      }
    }

    switch (riskProfile) {
      case RiskProfile.aggressive:
        handWeight += 1.5;
        cribWeight -= 0.3;
      case RiskProfile.balanced:
        break;
      case RiskProfile.conservative:
        if (!isDealer) {
          cribWeight += 1.5;
        } else {
          handWeight += 0.3;
          cribWeight += 0.5;
        }
      case RiskProfile.desperate:
        handWeight += 2.5;
        cribWeight -= 0.8;
    }

    if (playerDistanceFrom121 > 15 && playerDistanceFrom121 <= 30) {
      if (!isDealer) {
        final proximityBonus = (30 - playerDistanceFrom121) / 15.0;
        handWeight += 0.5 + proximityBonus;
      }
    }

    return handValue * handWeight + cribValue * cribWeight;
  }

  static double _estimateCribDamagePotential(List<PlayingCard> cards) {
    if (cards.length != 2) return 0.0;

    var damage = 0.0;
    final card1 = cards[0];
    final card2 = cards[1];

    if (card1.rank == card2.rank) {
      damage += 3.0;
    }
    if (card1.value + card2.value == 15) {
      damage += 2.5;
    }

    final rankDiff = (card1.rank.index - card2.rank.index).abs();
    if (rankDiff == 1) {
      damage += 2.0;
    } else if (rankDiff == 2) {
      damage += 1.0;
    }

    if ((card1.rank == Rank.five && card2.value == 10) ||
        (card2.rank == Rank.five && card1.value == 10)) {
      damage += 2.0;
    }
    if (card1.rank == Rank.five && card2.rank == Rank.five) {
      damage += 4.0;
    }
    if (card1.suit == card2.suit) {
      damage += 1.5;
    }
    if (card1.rank.index >= 3 &&
        card1.rank.index <= 8 &&
        card2.rank.index >= 3 &&
        card2.rank.index <= 8) {
      damage += 0.8;
    }
    if (card1.value == 10 && card2.value == 10 && card1.rank != card2.rank) {
      damage -= 1.5;
    }

    return damage;
  }

  static RiskProfile _calculateRiskProfile({
    required int scoreDiff,
    required int playerDistanceFrom121,
    required int opponentDistanceFrom121,
    required bool isDealer,
  }) {
    if (scoreDiff <= -20 && opponentDistanceFrom121 <= 25) {
      return RiskProfile.desperate;
    }
    if (scoreDiff <= -10) {
      return RiskProfile.aggressive;
    }
    if (scoreDiff >= 15 || (scoreDiff >= 8 && opponentDistanceFrom121 > 40)) {
      return RiskProfile.conservative;
    }
    return RiskProfile.balanced;
  }

  static double _estimateHandValue(List<PlayingCard> cards) {
    var score = 0.0;

    var pairCount = 0;
    for (var i = 0; i < cards.length; i++) {
      for (var j = i + 1; j < cards.length; j++) {
        if (cards[i].rank == cards[j].rank) {
          score += 2;
          pairCount++;
        }
      }
    }
    if (pairCount >= 2) {
      score += 1.5;
    }

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
    if (fifteenCount >= 3) {
      score += 1.0;
    }

    final runLength = _findBestRun(cards);
    if (runLength >= 3) {
      score += runLength * 1.2;
    }

    final suitCounts = cards.fold<Map<Suit, int>>(<Suit, int>{}, (acc, card) {
      acc.update(card.suit, (value) => value + 1, ifAbsent: () => 1);
      return acc;
    });
    if (suitCounts.values.any((count) => count == 4)) {
      score += 4;
    } else if (suitCounts.values.any((count) => count == 3)) {
      score += 0.5;
    }

    score += cards.where((card) => card.rank == Rank.five).length * 1.0;
    score += cards
            .where((card) => card.rank.index >= 3 && card.rank.index <= 8)
            .length *
        0.5;
    score += cards.where((card) => card.rank == Rank.ace).length * 0.3;

    final hasLow = cards.any((card) => card.value <= 5);
    final hasHigh = cards.any((card) => card.value >= 10);
    if (hasLow && hasHigh) {
      score += 0.8;
    }

    final faceCardCount = cards.where((card) => card.value == 10).length;
    if (faceCardCount >= 3) {
      score -= 1.0;
    }

    return score;
  }

  static double _estimateCribValue(List<PlayingCard> cards) {
    var value = 0.0;

    if (cards[0].rank == cards[1].rank) {
      value += 5;
    }
    if (cards[0].value + cards[1].value == 15) {
      value += 4;
    }

    value += cards.where((card) => card.rank == Rank.five).length * 3.0;

    final rankDiff = (cards[0].rank.index - cards[1].rank.index).abs();
    if (rankDiff == 1) {
      value += 2.5;
    } else if (rankDiff == 2) {
      value += 1.5;
    } else if (rankDiff == 3) {
      value += 0.5;
    }

    if (cards[0].suit == cards[1].suit) {
      value += 2.0;
    }

    final sum = cards[0].value + cards[1].value;
    if (sum == 5) {
      value += 2.0;
    } else if (sum == 10) {
      value += 1.5;
    }

    if (cards.every((card) => card.value == 10)) {
      value -= 2.0;
    }

    value += cards
            .where((card) => card.rank == Rank.ace || card.rank == Rank.two)
            .length *
        0.8;

    if (cards.any((card) => card.rank == Rank.king) &&
        cards.any((card) => card.rank == Rank.queen)) {
      value -= 1.5;
    }

    return value;
  }

  /// Finds the longest run in [cards], ignoring duplicate ranks.
  static int _findBestRun(List<PlayingCard> cards) {
    final uniqueSorted =
        cards.map((c) => c.rank.index).toSet().toList()..sort();
    for (var length = uniqueSorted.length; length >= 3; length--) {
      for (var i = 0; i <= uniqueSorted.length - length; i++) {
        final subset = uniqueSorted.sublist(i, i + length);
        var isRun = true;
        for (var j = 0; j < subset.length - 1; j++) {
          if (subset[j + 1] - subset[j] != 1) {
            isRun = false;
            break;
          }
        }
        if (isRun) return length;
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

    if (newCount == 31) score += 250;
    if (newCount == 15) score += 180;

    if (peggingPile.isNotEmpty && peggingPile.last.rank == card.rank) {
      if (opponentCardsRemaining <= 2) {
        score += 140;
      } else if (peggingPile.length <= 2) {
        score += 60;
      } else {
        score += 110;
      }

      if (peggingPile.length >= 2 &&
          peggingPile[peggingPile.length - 2].rank == card.rank) {
        score += 200;
      }
    }

    final runPotential = _evaluateRunPotential(card, peggingPile);
    score += runPotential * 100;

    if (newCount == 5) {
      score -= 80;
    } else if (newCount == 10) {
      score -= 70;
    } else if (newCount == 11) {
      score -= 65;
    } else if (newCount == 21) {
      score -= 100;
    } else if (newCount == 6) {
      score -= 50;
    }

    if (peggingPile.isNotEmpty &&
        peggingPile.last.rank == card.rank &&
        peggingPile.length <= 2 &&
        opponentCardsRemaining > 2) {
      score -= 40;
    }

    if (card.rank == Rank.five && currentCount < 6) {
      score -= 60;
    }

    if (newCount >= 27 && newCount <= 30) {
      score += 45;
    }

    if (currentCount < 10 && card.value <= 4) {
      score += 25;
    }

    if (currentCount >= 15 && card.value >= 8) {
      score += 20;
    }

    if (newCount >= 22 && newCount <= 25) {
      score -= 35;
    }

    if (opponentCardsRemaining <= 1) {
      score += 35;
    }

    if (currentCount < 12) {
      score += (5 - card.value) * 3;
    } else if (currentCount >= 15) {
      score += (card.value - 5) * 2.5;
    }

    if (card.rank.index >= 5 && card.rank.index <= 7) {
      score += 10;
    }

    return score;
  }

  static double _evaluateRunPotential(
    PlayingCard card,
    List<PlayingCard> pile,
  ) {
    if (pile.isEmpty) return 0;
    final newPile = List<PlayingCard>.from(pile)..add(card);
    for (var runLength = min(newPile.length, 7); runLength >= 3; runLength--) {
      final lastCards = newPile.sublist(newPile.length - runLength);
      final ranks = lastCards.map((c) => c.rank.index).toList();
      final distinct = ranks.toSet().toList()..sort();
      if (distinct.length != runLength) continue;
      var isRun = true;
      for (var i = 0; i < distinct.length - 1; i++) {
        if (distinct[i + 1] - distinct[i] != 1) {
          isRun = false;
          break;
        }
      }
      if (isRun) return runLength.toDouble();
    }
    return 0;
  }

  static List<List<int>> _combinations(List<int> items, int n) {
    if (n == 0) return [<int>[]];
    if (items.isEmpty) return [];
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

class _CribChoice {
  _CribChoice({required this.keep, required this.discard});

  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
}
