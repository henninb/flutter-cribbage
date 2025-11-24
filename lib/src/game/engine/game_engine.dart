import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../logic/cribbage_scorer.dart';
import '../logic/deal_utils.dart';
import '../logic/opponent_ai.dart';
import '../logic/pegging_round_manager.dart';
import '../models/card.dart';
import '../../services/game_persistence.dart';
import '../../utils/string_sanitizer.dart';
import 'game_state.dart';

class GameEngine extends ChangeNotifier {
  GameEngine({
    GamePersistence? persistence,
    Random? random,
  })  : _persistence = persistence,
        _random = random ?? Random();

  final GamePersistence? _persistence;
  final Random _random;
  GameState _state = const GameState();
  List<PlayingCard> _drawDeck = const [];
  PeggingRoundManager? _peggingManager;
  bool _opponentAutoplayScheduled = false;

  GameState get state => _state;

  void initialize() {
    final stats = _persistence?.loadStats();
    if (stats != null) {
      _state = _state.copyWith(
        gamesWon: stats.gamesWon,
        gamesLost: stats.gamesLost,
        skunksFor: stats.skunksFor,
        skunksAgainst: stats.skunksAgainst,
      );
    }
    final cut = _persistence?.loadCutCards();
    if (cut != null) {
      _state = _state.copyWith(
        cutPlayerCard: cut.player,
        cutOpponentCard: cut.opponent,
      );
    }
    final names = _persistence?.loadPlayerNames();
    if (names != null) {
      // Sanitize loaded names for security
      final sanitizedPlayerName = StringSanitizer.sanitizeNameWithDefault(
        names.playerName,
        'You',
      );
      final sanitizedOpponentName = StringSanitizer.sanitizeNameWithDefault(
        names.opponentName,
        'Opponent',
      );
      _state = _state.copyWith(
        playerName: sanitizedPlayerName,
        opponentName: sanitizedOpponentName,
      );
    }
    notifyListeners();
  }

  void startNewGame() {
    debugPrint('[SCORE] ===== NEW GAME STARTED =====');
    _peggingManager = null;
    _drawDeck = const [];
    _state = _state.copyWith(
      gameStarted: true,
      currentPhase: GamePhase.cutForDealer,
      gameStatus: 'Cut cards to determine the dealer.',
      playerScore: 0,
      opponentScore: 0,
      playerHand: const [],
      opponentHand: const [],
      cribHand: const [],
      selectedCards: const {},
      clearStarterCard: true,
      cutPlayerCard: null,
      cutOpponentCard: null,
      showCutForDealer: false,
      isPlayerTurn: false,
      isPeggingPhase: false,
      gameOver: false,
      showWinnerModal: false,
      winnerModalData: null,
      handScores: const HandScores(),
      countingPhase: CountingPhase.none,
      isInHandCountingPhase: false,
      // Reset pegging-related state
      playerCardsPlayed: const {},
      opponentCardsPlayed: const {},
      peggingCount: 0,
      peggingPile: const [],
      consecutiveGoes: 0,
      lastPlayerWhoPlayed: null,
      clearPendingReset: true,
      isOpponentActionInProgress: false,
      showCutCardDisplay: false,
      clearPlayerScoreAnimation: true,
      clearOpponentScoreAnimation: true,
    );
    notifyListeners();
  }

  void cutForDealer() {
    final deck = createDeck(random: _random);
    final playerCut = deck.first;
    final opponentCut = deck[1];
    _state = _state.copyWith(
      cutPlayerCard: playerCut,
      cutOpponentCard: opponentCut,
      showCutForDealer: true,
    );
    _persistence?.saveCutCards(playerCut, opponentCut);

    final dealer = dealerFromCut(playerCut, opponentCut);
    if (dealer == null) {
      _state = _state.copyWith(gameStatus: 'Tie! Cut again to determine dealer.');
    } else {
      final playerDeals = dealer == Player.player;
      _state = _state.copyWith(
        isPlayerDealer: playerDeals,
        currentPhase: GamePhase.dealing,
        gameStatus: playerDeals
            ? 'You are the dealer. Tap Deal to continue.'
            : 'Opponent deals. Tap Deal to continue.',
      );
    }
    notifyListeners();
  }

  void dealCards() {
    final deck = createDeck(random: _random);
    final result = dealSixToEach(deck, _state.isPlayerDealer);
    _drawDeck = result.remainingDeck;
    _state = _state.copyWith(
      playerHand: result.playerHand,
      opponentHand: result.opponentHand,
      currentPhase: GamePhase.cribSelection,
      selectedCards: const {},
      gameStatus: _state.isPlayerDealer
          ? 'Select two cards to give to your crib.'
          : 'Select two cards to give to the opponent\'s crib.',
    );
    notifyListeners();
  }

  void toggleCardSelection(int index) {
    final selected = Set<int>.from(_state.selectedCards);
    if (selected.contains(index)) {
      selected.remove(index);
    } else if (selected.length < 2) {
      selected.add(index);
    }
    _state = _state.copyWith(selectedCards: selected);
    notifyListeners();
  }

  /// Get AI advice for which 2 cards to discard to the crib
  /// Returns the indices of the cards to discard
  List<int> getAdvice() {
    if (_state.currentPhase != GamePhase.cribSelection || _state.playerHand.length != 6) {
      return [];
    }

    // Generate all possible combinations
    final combos = _generateCombinations(_state.playerHand);

    // Evaluate each combination with game position awareness
    combos.sort((a, b) {
      final scoreA = _evaluateCribChoiceWithPosition(a.keep, a.discard, _state.isPlayerDealer);
      final scoreB = _evaluateCribChoiceWithPosition(b.keep, b.discard, _state.isPlayerDealer);
      return scoreB.compareTo(scoreA);
    });

    // Get the best choice
    final bestChoice = combos.firstOrNull;
    if (bestChoice == null) {
      return [];
    }

    // Find the indices of the cards to discard
    final indices = <int>[];
    for (var i = 0; i < _state.playerHand.length; i++) {
      if (bestChoice.discard.contains(_state.playerHand[i])) {
        indices.add(i);
        if (indices.length == 2) break;
      }
    }

    return indices;
  }

  List<_CribChoice> _generateCombinations(List<PlayingCard> hand) {
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

  double _evaluateCribChoiceWithPosition(
    List<PlayingCard> keep,
    List<PlayingCard> discard,
    bool isDealer,
  ) {
    // Use the AI's base evaluation
    final handValue = _estimateHandValue(keep);
    final rawCribValue = _estimateCribValue(discard);

    // Calculate enhanced crib damage potential (cards that work well together)
    final cribDamagePotential = _estimateCribDamagePotential(discard);

    // Use enhanced crib evaluation
    final cribValue = isDealer
        ? rawCribValue
        : -(rawCribValue + cribDamagePotential);

    // Calculate game position factors
    final scoreDiff = _state.playerScore - _state.opponentScore;
    final playerDistanceFrom121 = 121 - _state.playerScore;
    final opponentDistanceFrom121 = 121 - _state.opponentScore;

    // Determine risk profile
    final riskProfile = _calculateRiskProfile(
      scoreDiff: scoreDiff,
      playerDistanceFrom121: playerDistanceFrom121,
      opponentDistanceFrom121: opponentDistanceFrom121,
      isDealer: isDealer,
    );

    // Base weights - adjusted by risk profile
    var handWeight = isDealer ? 3.5 : 4.0;
    var cribWeight = isDealer ? 1.0 : 1.3;

    // === CRITICAL ENDGAME SCENARIOS ===
    // When both players are very close, counting order is EVERYTHING
    if (playerDistanceFrom121 <= 15 && opponentDistanceFrom121 <= 15) {
      if (!isDealer) {
        // As pone, we count first - absolutely maximize hand value
        handWeight += 2.5;
        // And be EXTREMELY defensive about crib
        cribWeight += 2.0;
      } else {
        // As dealer, we need both hand AND crib, but they count first
        handWeight += 1.0;
        cribWeight += 1.5;
      }
    }

    // === OPPONENT WITHIN PEGGING DISTANCE ===
    // If opponent could peg out (within ~15 points), be very careful
    else if (opponentDistanceFrom121 <= 15) {
      if (!isDealer) {
        // Pone - we count first, so focus on hand but minimize crib damage
        handWeight += 1.5;
        cribWeight += 2.5; // VERY defensive
      } else {
        // Dealer - opponent counts first, so minimize their hand potential
        handWeight += 0.5;
        cribWeight += 1.0;
      }
    }

    // === WE'RE WITHIN WINNING DISTANCE ===
    else if (playerDistanceFrom121 <= 20) {
      if (!isDealer) {
        // Pone - counting order advantage is huge
        handWeight += 1.8;
        cribWeight += 1.0;
      } else {
        // Dealer - we have crib advantage
        handWeight += 0.8;
        cribWeight += 1.2;
      }
    }

    // === APPLY RISK PROFILE ADJUSTMENTS ===
    switch (riskProfile) {
      case RiskProfile.aggressive:
        // Behind significantly - take risks to maximize points
        handWeight += 1.5;
        // Still defend crib, but not as much as normal
        cribWeight -= 0.3;

      case RiskProfile.balanced:
        // Close game - standard strategy
        // No adjustments

      case RiskProfile.conservative:
        // Ahead - minimize variance and opponent's opportunities
        if (!isDealer) {
          // Pone - be VERY defensive about crib
          cribWeight += 1.5;
        } else {
          // Dealer - maximize total value conservatively
          handWeight += 0.3;
          cribWeight += 0.5;
        }

      case RiskProfile.desperate:
        // Way behind, opponent close to winning - swing for the fences
        handWeight += 2.5;
        // Accept some crib risk to maximize hand potential
        cribWeight -= 0.8;
    }

    // === COUNTING ORDER ADVANTAGE (non-critical games) ===
    if (playerDistanceFrom121 > 15 && playerDistanceFrom121 <= 30) {
      if (!isDealer) {
        // Pone advantage increases as we get closer to 121
        final proximityBonus = (30 - playerDistanceFrom121) / 15.0;
        handWeight += 0.5 + proximityBonus;
      }
    }

    return handValue * handWeight + cribValue * cribWeight;
  }

  /// Estimates additional crib damage potential based on card synergy
  /// Returns higher values for cards that work well together in opponent's crib
  double _estimateCribDamagePotential(List<PlayingCard> cards) {
    if (cards.length != 2) return 0.0;

    var damage = 0.0;
    final card1 = cards[0];
    final card2 = cards[1];

    // Pairs are devastating in crib (they often become multiple pairs with starter)
    if (card1.rank == card2.rank) {
      damage += 3.0; // Extra penalty for giving opponent a pair
    }

    // Cards that make 15 together are very strong
    if (card1.value + card2.value == 15) {
      damage += 2.5;
    }

    // Sequential cards have high run potential
    final rankDiff = (card1.rank.index - card2.rank.index).abs();
    if (rankDiff == 1) {
      damage += 2.0; // Adjacent cards are dangerous
    } else if (rankDiff == 2) {
      damage += 1.0; // One-gapped cards still have potential
    }

    // Fives with face cards are excellent for opponent
    if ((card1.rank == Rank.five && card2.value == 10) ||
        (card2.rank == Rank.five && card1.value == 10)) {
      damage += 2.0;
    }

    // Two fives is nightmare fuel
    if (card1.rank == Rank.five && card2.rank == Rank.five) {
      damage += 4.0;
    }

    // Same suit gives flush potential
    if (card1.suit == card2.suit) {
      damage += 1.5;
    }

    // Mid-range cards (4-9) together are versatile
    if (card1.rank.index >= 3 && card1.rank.index <= 8 &&
        card2.rank.index >= 3 && card2.rank.index <= 8) {
      damage += 0.8;
    }

    // Two face cards together are actually weak (less damage than expected)
    if (card1.value == 10 && card2.value == 10 && card1.rank != card2.rank) {
      damage -= 1.5; // Actually safer to give opponent dead cards
    }

    return damage;
  }

  /// Calculates risk profile based on game situation
  RiskProfile _calculateRiskProfile({
    required int scoreDiff,
    required int playerDistanceFrom121,
    required int opponentDistanceFrom121,
    required bool isDealer,
  }) {
    // Desperate: Way behind (20+) and opponent is close to winning (within 25)
    if (scoreDiff <= -20 && opponentDistanceFrom121 <= 25) {
      return RiskProfile.desperate;
    }

    // Aggressive: Behind significantly (10-20 points)
    if (scoreDiff <= -10) {
      return RiskProfile.aggressive;
    }

    // Conservative: Ahead significantly (15+) or ahead with opponent far from winning
    if (scoreDiff >= 15 || (scoreDiff >= 8 && opponentDistanceFrom121 > 40)) {
      return RiskProfile.conservative;
    }

    // Balanced: Close game
    return RiskProfile.balanced;
  }

  double _estimateHandValue(List<PlayingCard> cards) {
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

    if (pairCount >= 2) {
      score += 1.5;
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

    if (fifteenCount >= 3) {
      score += 1.0;
    }

    // Evaluate runs
    final runLength = _findBestRun(cards);
    if (runLength >= 3) {
      score += runLength * 1.2;
    }

    // Flush potential
    final suitCounts = cards.fold<Map<Suit, int>>(<Suit, int>{}, (acc, card) {
      acc.update(card.suit, (value) => value + 1, ifAbsent: () => 1);
      return acc;
    });
    if (suitCounts.values.any((count) => count == 4)) {
      score += 4;
    } else if (suitCounts.values.any((count) => count == 3)) {
      score += 0.5;
    }

    // Fives are valuable
    score += cards.where((card) => card.rank == Rank.five).length * 1.0;

    // Middle-range cards are versatile
    score += cards.where((card) => card.rank.index >= 3 && card.rank.index <= 8).length * 0.5;

    // Aces are flexible
    score += cards.where((card) => card.rank == Rank.ace).length * 0.3;

    // Having both high and low cards
    final hasLow = cards.any((card) => card.value <= 5);
    final hasHigh = cards.any((card) => card.value >= 10);
    if (hasLow && hasHigh) {
      score += 0.8;
    }

    // Penalize too many face cards
    final faceCardCount = cards.where((card) => card.value == 10).length;
    if (faceCardCount >= 3) {
      score -= 1.0;
    }

    return score;
  }

  double _estimateCribValue(List<PlayingCard> cards) {
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

    value += cards.where((card) => card.rank == Rank.ace || card.rank == Rank.two).length * 0.8;

    if (cards.any((card) => card.rank == Rank.king) &&
        cards.any((card) => card.rank == Rank.queen)) {
      value -= 1.5;
    }

    return value;
  }

  int _findBestRun(List<PlayingCard> cards) {
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

  List<List<int>> _combinations(List<int> items, int n) {
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

  void confirmCribSelection() {
    if (_state.selectedCards.length != 2) {
      return;
    }
    final indices = _state.selectedCards.toList()..sort();
    final playerHand = List<PlayingCard>.from(_state.playerHand);
    final crib = <PlayingCard>[playerHand[indices[0]], playerHand[indices[1]]];
    playerHand.removeAt(indices[1]);
    playerHand.removeAt(indices[0]);

    final opponentCrib = OpponentAI.chooseCribCards(
      _state.opponentHand,
      !_state.isPlayerDealer,
    );
    final opponentHand = _state.opponentHand.where((card) => !opponentCrib.contains(card)).toList();
    crib.addAll(opponentCrib);

    final starter = _drawDeck.isNotEmpty ? _drawDeck.first : null;
    _drawDeck = _drawDeck.skip(1).toList();

    debugPrint('[ROUND] ===== New Round Starting =====');
    debugPrint('[ROUND] Dealer: ${_state.isPlayerDealer ? "Player" : "Opponent"}');
    debugPrint('[ROUND] Player Hand: ${playerHand.map((c) => c.label).join(", ")}');
    debugPrint('[ROUND] Opponent Hand: ${opponentHand.map((c) => c.label).join(", ")}');
    debugPrint('[ROUND] Crib: ${crib.map((c) => c.label).join(", ")}');
    debugPrint('[ROUND] Starter Card: ${starter?.label ?? "?"}');

    var playerScore = _state.playerScore;
    var opponentScore = _state.opponentScore;
    var status = 'Starter card: ${starter?.label ?? '?'}';
    ScoreAnimation? hisHeelsAnimation;
    if (starter?.rank == Rank.jack) {
      if (_state.isPlayerDealer) {
        playerScore += 2;
        status += '\nYou scored 2 for His Heels!';
        debugPrint('[SCORE] His Heels: Player (dealer) scored 2 for Jack starter (${_state.playerScore} -> $playerScore)');
        hisHeelsAnimation = ScoreAnimation(
          points: 2,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        opponentScore += 2;
        status += '\nOpponent scored 2 for His Heels!';
        debugPrint('[SCORE] His Heels: Opponent (dealer) scored 2 for Jack starter (${_state.opponentScore} -> $opponentScore)');
        hisHeelsAnimation = ScoreAnimation(
          points: 2,
          isPlayer: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    _peggingManager = PeggingRoundManager(
      startingPlayer: _state.isPlayerDealer ? Player.opponent : Player.player,
    );

    _state = _state.copyWith(
      playerHand: playerHand,
      opponentHand: opponentHand,
      cribHand: crib,
      starterCard: starter,
      selectedCards: const {},
      currentPhase: GamePhase.pegging,
      isPeggingPhase: true,
      isPlayerTurn: !_state.isPlayerDealer,
      peggingCount: 0,
      peggingPile: const [],
      playerCardsPlayed: const {},
      opponentCardsPlayed: const {},
      playerScore: playerScore,
      opponentScore: opponentScore,
      gameStatus: status + (_state.isPlayerDealer ? '\nOpponent plays first.' : '\nYour turn to play.'),
      peggingManager: _peggingManager,
      playerScoreAnimation: hisHeelsAnimation?.isPlayer == true ? hisHeelsAnimation : null,
      opponentScoreAnimation: hisHeelsAnimation?.isPlayer == false ? hisHeelsAnimation : null,
    );
    notifyListeners();
    _maybeAutoplayOpponent();
  }

  void playCard(int cardIndex, {bool isPlayer = true}) {
    if (isPlayer && (!_state.isPlayerTurn || _state.currentPhase != GamePhase.pegging)) {
      return;
    }
    final hand = isPlayer ? _state.playerHand : _state.opponentHand;
    final played = isPlayer ? _state.playerCardsPlayed : _state.opponentCardsPlayed;
    if (cardIndex < 0 || cardIndex >= hand.length || played.contains(cardIndex)) {
      return;
    }
    final mgr = _peggingManager;
    if (mgr == null) {
      return;
    }
    final card = hand[cardIndex];
    if (mgr.peggingCount + card.value > 31) {
      return;
    }

    // Calculate pile and count BEFORE calling onPlay, as onPlay may reset them
    // (e.g., when reaching 31). This ensures we score the correct pile state.
    final pileBeforePlay = List<PlayingCard>.from(mgr.peggingPile)..add(card);
    final countBeforePlay = mgr.peggingCount + card.value;

    debugPrint('[PEGGING] ${isPlayer ? "Player" : "Opponent"} plays ${card.label} (value: ${card.value})');
    debugPrint('[PEGGING] Pile after play: ${pileBeforePlay.map((c) => c.label).join(", ")} | Count: $countBeforePlay');

    final outcome = mgr.onPlay(card);
    final pileAfter = List<PlayingCard>.from(mgr.peggingPile);
    final countAfter = mgr.peggingCount;
    final points = CribbageScorer.pointsForPile(pileBeforePlay, countBeforePlay);

    var status = _state.gameStatus;
    var playerScore = _state.playerScore;
    var opponentScore = _state.opponentScore;
    ScoreAnimation? peggingAnimation;

    if (points.total > 0) {
      final breakdown = [];
      if (points.fifteen > 0) breakdown.add('15 for ${points.fifteen}');
      if (points.thirtyOne > 0) breakdown.add('31 for ${points.thirtyOne}');
      if (points.pairPoints > 0) breakdown.add('${points.sameRankCount}-of-kind for ${points.pairPoints}');
      if (points.runPoints > 0) breakdown.add('run of ${points.runPoints}');

      if (isPlayer) {
        playerScore += points.total;
        status += '\nYou scored ${points.total}.';
        debugPrint('[SCORE] Pegging: Player scored ${points.total} [${breakdown.join(", ")}] (${_state.playerScore} -> $playerScore)');
        peggingAnimation = ScoreAnimation(
          points: points.total,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        opponentScore += points.total;
        status += '\nOpponent scored ${points.total}.';
        debugPrint('[SCORE] Pegging: Opponent scored ${points.total} [${breakdown.join(", ")}] (${_state.opponentScore} -> $opponentScore)');
        peggingAnimation = ScoreAnimation(
          points: points.total,
          isPlayer: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } else {
      debugPrint('[PEGGING] No points scored');
    }

    final updatedPlayed = Set<int>.from(played)..add(cardIndex);

    // Only update score animations if points were scored, otherwise preserve existing animations
    final stateUpdate = _state.copyWith(
      peggingCount: countAfter,
      peggingPile: pileAfter,
      isPlayerTurn: mgr.isPlayerTurn == Player.player,
      playerCardsPlayed: isPlayer ? updatedPlayed : _state.playerCardsPlayed,
      opponentCardsPlayed: isPlayer ? _state.opponentCardsPlayed : updatedPlayed,
      playerScore: playerScore,
      opponentScore: opponentScore,
      gameStatus: status,
      peggingManager: mgr,
    );

    // Apply animation updates only if there are points to show
    _state = peggingAnimation != null
        ? stateUpdate.copyWith(
            playerScoreAnimation: peggingAnimation.isPlayer ? peggingAnimation : null,
            opponentScoreAnimation: !peggingAnimation.isPlayer ? peggingAnimation : null,
          )
        : stateUpdate;
    notifyListeners();

    if (outcome.reset != null && outcome.reset!.resetFor31) {
      _state = _state.copyWith(
        pendingReset: PendingResetState(
          pile: pileBeforePlay, // Use pile before reset, not after
          finalCount: 31,
          scoreAwarded: points.total,
          message: '31! Pile reset.',
        ),
      );
      notifyListeners();
      _checkPeggingComplete();
      _checkGameOver();
      // Don't call _maybeAutoplayOpponent here - wait for acknowledgePendingReset
      return;
    }

    _checkPeggingComplete();
    _checkGameOver();
    _maybeAutoplayOpponent();
  }

  void handleGo({bool fromPlayer = true}) {
    final mgr = _peggingManager;
    if (mgr == null) {
      return;
    }
    final opponentHasMove = fromPlayer ? _opponentHasLegalMove() : _playerHasLegalMove();
    final pileBeforeReset = List<PlayingCard>.from(mgr.peggingPile);
    final countBeforeReset = mgr.peggingCount;

    debugPrint('[PEGGING] ${fromPlayer ? "Player" : "Opponent"} says Go');
    debugPrint('[PEGGING] Pile at Go: ${pileBeforeReset.map((c) => c.label).join(", ")} | Count: $countBeforeReset');

    final reset = mgr.onGo(opponentHasLegalMove: opponentHasMove);
    if (reset != null) {
      var playerScore = _state.playerScore;
      var opponentScore = _state.opponentScore;
      var scoreAwarded = 0;
      ScoreAnimation? goAnimation;
      if (reset.goPointTo == Player.player) {
        playerScore += 1;
        scoreAwarded = 1;
        debugPrint('[SCORE] Go: Player scored 1 (${_state.playerScore} -> $playerScore)');
        goAnimation = ScoreAnimation(
          points: 1,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else if (reset.goPointTo == Player.opponent) {
        opponentScore += 1;
        scoreAwarded = 1;
        debugPrint('[SCORE] Go: Opponent scored 1 (${_state.opponentScore} -> $opponentScore)');
        goAnimation = ScoreAnimation(
          points: 1,
          isPlayer: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // Show pending reset dialog for Go (similar to 31)
      _state = _state.copyWith(
        isPlayerTurn: mgr.isPlayerTurn == Player.player,
        playerScore: playerScore,
        opponentScore: opponentScore,
        peggingManager: mgr,
        peggingPile: List<PlayingCard>.from(mgr.peggingPile), // Manager has cleared the pile
        peggingCount: mgr.peggingCount, // Manager has reset count to 0
        pendingReset: PendingResetState(
          pile: pileBeforeReset,
          finalCount: countBeforeReset,
          scoreAwarded: scoreAwarded,
          message: 'Go! Pile reset.',
        ),
        playerScoreAnimation: goAnimation?.isPlayer == true ? goAnimation : null,
        opponentScoreAnimation: goAnimation?.isPlayer == false ? goAnimation : null,
      );
      notifyListeners();
      _checkPeggingComplete();
      // Don't call _maybeAutoplayOpponent here - wait for acknowledgePendingReset
      return;
    } else {
      _state = _state.copyWith(
        isPlayerTurn: mgr.isPlayerTurn == Player.player,
        peggingManager: mgr,
      );
      notifyListeners();
    }
    _checkPeggingComplete();
    _maybeAutoplayOpponent();
  }

  void acknowledgePendingReset() {
    _state = _state.copyWith(
      clearPendingReset: true,
      peggingPile: const [],
      peggingCount: 0,
    );
    notifyListeners();
    _checkPeggingComplete();
    _maybeAutoplayOpponent();
  }

  void startHandCounting() {
    if (_state.currentPhase != GamePhase.handCounting) {
      debugPrint('[COUNTING ERROR] Not in handCounting phase: ${_state.currentPhase}');
      return;
    }

    final starter = _state.starterCard;
    if (starter == null) {
      debugPrint('[COUNTING ERROR] No starter card!');
      return;
    }

    // Clear pegging history and pile now that user is moving to hand counting
    final mgr = _peggingManager;
    if (mgr != null) {
      mgr.completedRounds.clear();
      mgr.peggingPile.clear();
    }

    // Clear pegging pile in state as well
    _state = _state.copyWith(
      peggingPile: const [],
      peggingCount: 0,
    );

    // Debug: Check hand sizes
    debugPrint('[COUNTING DEBUG] Player hand size: ${_state.playerHand.length}, Opponent hand size: ${_state.opponentHand.length}');
    debugPrint('[COUNTING DEBUG] Player hand: ${_state.playerHand.map((c) => c.label).join(", ")}');
    debugPrint('[COUNTING DEBUG] Opponent hand: ${_state.opponentHand.map((c) => c.label).join(", ")}');

    // Calculate non-dealer hand breakdown first
    final hand = _state.isPlayerDealer ? _state.opponentHand : _state.playerHand;
    debugPrint('[COUNTING DEBUG] Non-dealer hand to score: ${hand.map((c) => c.label).join(", ")}');

    final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
    debugPrint('[COUNTING] Non-Dealer Hand: ${hand.map((c) => c.label).join(", ")} + Starter: ${starter.label}');
    debugPrint('[COUNTING] Breakdown total: ${breakdown.totalScore}, entries: ${breakdown.entries.length}');
    debugPrint('[COUNTING] Breakdown: ${breakdown.entries.map((e) => "${e.type} ${e.cards.map((c) => c.label).join(",")} = ${e.points}").join(" | ")}');

    // Set state with breakdown BEFORE showing dialog
    // DON'T update scores or create animations yet - wait for user to click Continue
    _state = _state.copyWith(
      isInHandCountingPhase: true,
      countingPhase: CountingPhase.nonDealer,
      handScores: _state.handScores.copyWith(
        nonDealerScore: breakdown.totalScore,
        nonDealerBreakdown: breakdown,
      ),
    );

    debugPrint('[COUNTING DEBUG] After state update - handScores.nonDealerBreakdown entries: ${_state.handScores.nonDealerBreakdown?.entries.length}');

    // Don't check for game over yet - wait until all hands are counted (crib case handles this)
    notifyListeners();
    debugPrint('[COUNTING DEBUG] notifyListeners() called');
  }

  void proceedToNextCountingPhase() {
    final phase = _state.countingPhase;
    final starter = _state.starterCard;
    if (starter == null) {
      return;
    }

    switch (phase) {
      case CountingPhase.nonDealer:
        // Apply non-dealer score and create animation NOW (user clicked Continue)
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        final nonDealerScore = _state.handScores.nonDealerScore;
        ScoreAnimation? nonDealerAnimation;

        if (_state.isPlayerDealer) {
          opponentScore += nonDealerScore;
          debugPrint('[SCORE] Non-Dealer Hand: Opponent scored $nonDealerScore (${_state.opponentScore} -> $opponentScore)');
          if (nonDealerScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: nonDealerScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          playerScore += nonDealerScore;
          debugPrint('[SCORE] Non-Dealer Hand: Player scored $nonDealerScore (${_state.playerScore} -> $playerScore)');
          if (nonDealerScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: nonDealerScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Check if game is over after non-dealer score
        if (playerScore > 120 || opponentScore > 120) {
          debugPrint('[SCORE] Game over after non-dealer hand. Player=$playerScore, Opponent=$opponentScore');
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            isInHandCountingPhase: false,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation: nonDealerAnimation != null && nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
            opponentScoreAnimation: nonDealerAnimation != null && !nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Now calculate dealer phase and store breakdown (but don't apply score yet)
        final hand = _state.isPlayerDealer ? _state.playerHand : _state.opponentHand;
        final breakdown = CribbageScorer.scoreHandWithBreakdown(hand, starter, false);
        debugPrint('[COUNTING] Dealer Hand: ${hand.map((c) => c.label).join(", ")} + Starter: ${starter.label}');
        debugPrint('[COUNTING] Breakdown: ${breakdown.entries.map((e) => "${e.type} ${e.cards.map((c) => c.label).join(",")} = ${e.points}").join(" | ")}');

        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            dealerScore: breakdown.totalScore,
            dealerBreakdown: breakdown,
          ),
          countingPhase: CountingPhase.dealer,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: nonDealerAnimation != null && nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
          opponentScoreAnimation: nonDealerAnimation != null && !nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
        );
        break;

      case CountingPhase.dealer:
        // Apply dealer score and create animation NOW (user clicked Continue)
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        final dealerScore = _state.handScores.dealerScore;
        ScoreAnimation? dealerAnimation;

        if (_state.isPlayerDealer) {
          playerScore += dealerScore;
          debugPrint('[SCORE] Dealer Hand: Player scored $dealerScore (${_state.playerScore} -> $playerScore)');
          if (dealerScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: dealerScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += dealerScore;
          debugPrint('[SCORE] Dealer Hand: Opponent scored $dealerScore (${_state.opponentScore} -> $opponentScore)');
          if (dealerScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: dealerScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Check if game is over after dealer score
        if (playerScore > 120 || opponentScore > 120) {
          debugPrint('[SCORE] Game over after dealer hand. Player=$playerScore, Opponent=$opponentScore');
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            isInHandCountingPhase: false,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation: dealerAnimation != null && dealerAnimation.isPlayer ? dealerAnimation : null,
            opponentScoreAnimation: dealerAnimation != null && !dealerAnimation.isPlayer ? dealerAnimation : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Now calculate crib phase and store breakdown (but don't apply score yet)
        final breakdown = CribbageScorer.scoreHandWithBreakdown(
          _state.cribHand,
          starter,
          true,
        );
        debugPrint('[COUNTING] Crib: ${_state.cribHand.map((c) => c.label).join(", ")} + Starter: ${starter.label}');
        debugPrint('[COUNTING] Breakdown: ${breakdown.entries.map((e) => "${e.type} ${e.cards.map((c) => c.label).join(",")} = ${e.points}").join(" | ")}');

        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            cribScore: breakdown.totalScore,
            cribBreakdown: breakdown,
          ),
          countingPhase: CountingPhase.crib,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: dealerAnimation != null && dealerAnimation.isPlayer ? dealerAnimation : null,
          opponentScoreAnimation: dealerAnimation != null && !dealerAnimation.isPlayer ? dealerAnimation : null,
        );
        debugPrint('[COUNTING DEBUG] After dealer phase - countingPhase: ${_state.countingPhase}, isInHandCountingPhase: ${_state.isInHandCountingPhase}, playerScore: $playerScore, opponentScore: $opponentScore');
        break;

      case CountingPhase.crib:
        // Apply crib score and create animation NOW (user clicked Continue)
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        final cribScore = _state.handScores.cribScore;
        ScoreAnimation? cribAnimation;

        if (_state.isPlayerDealer) {
          playerScore += cribScore;
          debugPrint('[SCORE] Crib: Player (dealer) scored $cribScore (${_state.playerScore} -> $playerScore)');
          if (cribScore > 0) {
            cribAnimation = ScoreAnimation(
              points: cribScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += cribScore;
          debugPrint('[SCORE] Crib: Opponent (dealer) scored $cribScore (${_state.opponentScore} -> $opponentScore)');
          if (cribScore > 0) {
            cribAnimation = ScoreAnimation(
              points: cribScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Complete counting phase
        debugPrint('[SCORE] Round complete. Final scores: Player=$playerScore, Opponent=$opponentScore');
        _state = _state.copyWith(
          countingPhase: CountingPhase.completed,
          isInHandCountingPhase: false,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: cribAnimation != null && cribAnimation.isPlayer ? cribAnimation : null,
          opponentScoreAnimation: cribAnimation != null && !cribAnimation.isPlayer ? cribAnimation : null,
        );
        _checkGameOver();
        if (!_state.gameOver) {
          _startNewRound();
        }
        notifyListeners();
        return;

      default:
        return;
    }

    // Don't check for game over yet - wait until all hands are counted (crib case handles this)
    notifyListeners();
  }

  /// Process manual score input and proceed to next counting phase
  void proceedToNextCountingPhaseWithManualScore(int manualScore) {
    final phase = _state.countingPhase;
    final starter = _state.starterCard;
    if (starter == null) {
      return;
    }

    switch (phase) {
      case CountingPhase.nonDealer:
        // Apply manual non-dealer score
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        ScoreAnimation? nonDealerAnimation;

        if (_state.isPlayerDealer) {
          opponentScore += manualScore;
          debugPrint('[SCORE] Non-Dealer Hand (Manual): Opponent scored $manualScore (${_state.opponentScore} -> $opponentScore)');
          if (manualScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          playerScore += manualScore;
          debugPrint('[SCORE] Non-Dealer Hand (Manual): Player scored $manualScore (${_state.playerScore} -> $playerScore)');
          if (manualScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Check if game is over after non-dealer score
        if (playerScore > 120 || opponentScore > 120) {
          debugPrint('[SCORE] Game over after non-dealer hand. Player=$playerScore, Opponent=$opponentScore');
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            isInHandCountingPhase: false,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation: nonDealerAnimation != null && nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
            opponentScoreAnimation: nonDealerAnimation != null && !nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Calculate dealer hand breakdown for next phase
        final dealerHand = _state.isPlayerDealer ? _state.playerHand : _state.opponentHand;
        final dealerBreakdown = CribbageScorer.scoreHandWithBreakdown(dealerHand, starter, false);
        debugPrint('[COUNTING] Dealer Hand: ${dealerHand.map((c) => c.label).join(", ")} + Starter: ${starter.label}');
        debugPrint('[COUNTING] Dealer Breakdown: ${dealerBreakdown.entries.map((e) => "${e.type} ${e.cards.map((c) => c.label).join(",")} = ${e.points}").join(" | ")}');

        // Move to dealer phase (score will be entered manually next)
        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            nonDealerScore: manualScore,
            dealerScore: dealerBreakdown.totalScore,
            dealerBreakdown: dealerBreakdown,
          ),
          countingPhase: CountingPhase.dealer,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: nonDealerAnimation != null && nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
          opponentScoreAnimation: nonDealerAnimation != null && !nonDealerAnimation.isPlayer ? nonDealerAnimation : null,
        );
        break;

      case CountingPhase.dealer:
        // Apply manual dealer score
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        ScoreAnimation? dealerAnimation;

        if (_state.isPlayerDealer) {
          playerScore += manualScore;
          debugPrint('[SCORE] Dealer Hand (Manual): Player scored $manualScore (${_state.playerScore} -> $playerScore)');
          if (manualScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += manualScore;
          debugPrint('[SCORE] Dealer Hand (Manual): Opponent scored $manualScore (${_state.opponentScore} -> $opponentScore)');
          if (manualScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Check if game is over after dealer score
        if (playerScore > 120 || opponentScore > 120) {
          debugPrint('[SCORE] Game over after dealer hand. Player=$playerScore, Opponent=$opponentScore');
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            isInHandCountingPhase: false,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation: dealerAnimation != null && dealerAnimation.isPlayer ? dealerAnimation : null,
            opponentScoreAnimation: dealerAnimation != null && !dealerAnimation.isPlayer ? dealerAnimation : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Calculate crib breakdown for next phase (crib is always counted as "in crib")
        final cribBreakdown = CribbageScorer.scoreHandWithBreakdown(_state.cribHand, starter, true);
        debugPrint('[COUNTING] Crib: ${_state.cribHand.map((c) => c.label).join(", ")} + Starter: ${starter.label}');
        debugPrint('[COUNTING] Crib Breakdown: ${cribBreakdown.entries.map((e) => "${e.type} ${e.cards.map((c) => c.label).join(",")} = ${e.points}").join(" | ")}');

        // Move to crib phase (score will be entered manually next)
        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            dealerScore: manualScore,
            cribScore: cribBreakdown.totalScore,
            cribBreakdown: cribBreakdown,
          ),
          countingPhase: CountingPhase.crib,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: dealerAnimation != null && dealerAnimation.isPlayer ? dealerAnimation : null,
          opponentScoreAnimation: dealerAnimation != null && !dealerAnimation.isPlayer ? dealerAnimation : null,
        );
        break;

      case CountingPhase.crib:
        // Apply manual crib score
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        ScoreAnimation? cribAnimation;

        if (_state.isPlayerDealer) {
          playerScore += manualScore;
          debugPrint('[SCORE] Crib (Manual): Player (dealer) scored $manualScore (${_state.playerScore} -> $playerScore)');
          if (manualScore > 0) {
            cribAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += manualScore;
          debugPrint('[SCORE] Crib (Manual): Opponent (dealer) scored $manualScore (${_state.opponentScore} -> $opponentScore)');
          if (manualScore > 0) {
            cribAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Complete counting phase
        debugPrint('[SCORE] Round complete. Final scores: Player=$playerScore, Opponent=$opponentScore');
        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            cribScore: manualScore,
          ),
          countingPhase: CountingPhase.completed,
          isInHandCountingPhase: false,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: cribAnimation != null && cribAnimation.isPlayer ? cribAnimation : null,
          opponentScoreAnimation: cribAnimation != null && !cribAnimation.isPlayer ? cribAnimation : null,
        );
        _checkGameOver();
        if (!_state.gameOver) {
          _startNewRound();
        }
        notifyListeners();
        return;

      default:
        return;
    }

    notifyListeners();
  }

  void dismissWinnerModal() {
    _state = _state.copyWith(showWinnerModal: false);
    notifyListeners();
  }

  void clearScoreAnimation(bool isPlayer) {
    if (isPlayer) {
      _state = _state.copyWith(clearPlayerScoreAnimation: true);
    } else {
      _state = _state.copyWith(clearOpponentScoreAnimation: true);
    }
    notifyListeners();
  }

  void updatePlayerName(bool isPlayer, String newName) {
    // Sanitize the name for security and UI consistency
    final defaultName = isPlayer ? 'You' : 'Opponent';
    final sanitizedName = StringSanitizer.sanitizeNameWithDefault(
      newName,
      defaultName,
    );

    if (isPlayer) {
      _state = _state.copyWith(playerName: sanitizedName);
    } else {
      _state = _state.copyWith(opponentName: sanitizedName);
    }
    _persistence?.savePlayerNames(
      playerName: _state.playerName,
      opponentName: _state.opponentName,
    );
    notifyListeners();
  }

  void updateScores(int newPlayerScore, int newOpponentScore) {
    debugPrint('[DEBUG SCORE] Updating scores: Player ${_state.playerScore} -> $newPlayerScore, Opponent ${_state.opponentScore} -> $newOpponentScore');

    // Calculate deltas to create animations
    final playerDelta = newPlayerScore - _state.playerScore;
    final opponentDelta = newOpponentScore - _state.opponentScore;

    ScoreAnimation? playerAnimation;
    ScoreAnimation? opponentAnimation;

    // Create animations for positive deltas
    if (playerDelta > 0) {
      playerAnimation = ScoreAnimation(
        points: playerDelta,
        isPlayer: true,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
    if (opponentDelta > 0) {
      opponentAnimation = ScoreAnimation(
        points: opponentDelta,
        isPlayer: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Only update animations if there are positive deltas to show
    final stateUpdate = _state.copyWith(
      playerScore: newPlayerScore,
      opponentScore: newOpponentScore,
    );

    _state = (playerAnimation != null || opponentAnimation != null)
        ? stateUpdate.copyWith(
            playerScoreAnimation: playerAnimation,
            opponentScoreAnimation: opponentAnimation,
          )
        : stateUpdate;
    notifyListeners();
  }

  bool get playerHasLegalMove => _playerHasLegalMove();

  bool get opponentHasLegalMove => _opponentHasLegalMove();

  bool isPlayerCardPlayable(int index) {
    if (_state.currentPhase != GamePhase.pegging || index < 0 || index >= _state.playerHand.length) {
      return false;
    }
    if (_state.playerCardsPlayed.contains(index)) {
      return false;
    }
    final mgr = _peggingManager;
    if (mgr == null) {
      return false;
    }
    return mgr.peggingCount + _state.playerHand[index].value <= 31;
  }

  bool _opponentHasLegalMove() {
    final mgr = _peggingManager;
    if (mgr == null) {
      return false;
    }
    for (var i = 0; i < _state.opponentHand.length; i++) {
      if (_state.opponentCardsPlayed.contains(i)) continue;
      if (mgr.peggingCount + _state.opponentHand[i].value <= 31) {
        return true;
      }
    }
    return false;
  }

  bool _playerHasLegalMove() {
    final mgr = _peggingManager;
    if (mgr == null) {
      return false;
    }
    for (var i = 0; i < _state.playerHand.length; i++) {
      if (_state.playerCardsPlayed.contains(i)) continue;
      if (mgr.peggingCount + _state.playerHand[i].value <= 31) {
        return true;
      }
    }
    return false;
  }

  void _checkPeggingComplete() {
    if (_state.playerCardsPlayed.length == 4 && _state.opponentCardsPlayed.length == 4) {
      // Award 1 point for last card if count is not 31
      // (If count is 31, the 2 points for 31 were already awarded)
      var playerScore = _state.playerScore;
      var opponentScore = _state.opponentScore;
      var status = _state.gameStatus;
      ScoreAnimation? lastCardAnimation;

      final mgr = _peggingManager;
      if (mgr != null && mgr.peggingCount > 0 && mgr.peggingCount != 31) {
        // Last player who played gets 1 point for last card
        if (mgr.lastPlayerWhoPlayed == Player.player) {
          playerScore += 1;
          status += '\nYou scored 1 for last card.';
          debugPrint('[SCORE] Last Card: Player scored 1 (${_state.playerScore} -> $playerScore)');
          lastCardAnimation = ScoreAnimation(
            points: 1,
            isPlayer: true,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        } else if (mgr.lastPlayerWhoPlayed == Player.opponent) {
          opponentScore += 1;
          status += '\nOpponent scored 1 for last card.';
          debugPrint('[SCORE] Last Card: Opponent scored 1 (${_state.opponentScore} -> $opponentScore)');
          lastCardAnimation = ScoreAnimation(
            points: 1,
            isPlayer: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }

      // Only update animations if last card scored, otherwise preserve existing animations
      final stateUpdate = _state.copyWith(
        isPeggingPhase: false,
        currentPhase: GamePhase.handCounting,
        gameStatus: '$status\nPegging complete. Count hands.',
        isPlayerTurn: false,
        playerScore: playerScore,
        opponentScore: opponentScore,
      );

      _state = lastCardAnimation != null
          ? stateUpdate.copyWith(
              playerScoreAnimation: lastCardAnimation.isPlayer ? lastCardAnimation : null,
              opponentScoreAnimation: !lastCardAnimation.isPlayer ? lastCardAnimation : null,
            )
          : stateUpdate;
      notifyListeners();
    }
  }

  void _startNewRound() {
    _state = _state.copyWith(
      currentPhase: GamePhase.dealing,
      isPlayerDealer: !_state.isPlayerDealer,
      countingPhase: CountingPhase.none,
      handScores: const HandScores(),
      playerHand: const [],
      opponentHand: const [],
      cribHand: const [],
      clearStarterCard: true,
      selectedCards: const {},
      peggingPile: const [],
      peggingCount: 0,
      playerCardsPlayed: const {},
      opponentCardsPlayed: const {},
      showCutForDealer: false,
      gameStatus: _state.isPlayerDealer
          ? 'Opponent is now the dealer.'
          : 'You are now the dealer.',
    );
    notifyListeners();
  }

  void _checkGameOver() {
    if (_state.playerScore <= 120 && _state.opponentScore <= 120) {
      return;
    }
    final playerWins = _state.playerScore > _state.opponentScore;
    final loserScore = playerWins ? _state.opponentScore : _state.playerScore;
    final skunked = loserScore < 91;
    final gamesWon = playerWins ? _state.gamesWon + 1 : _state.gamesWon;
    final gamesLost = playerWins ? _state.gamesLost : _state.gamesLost + 1;
    final skunksFor = playerWins && skunked ? _state.skunksFor + 1 : _state.skunksFor;
    final skunksAgainst = !playerWins && skunked
        ? _state.skunksAgainst + 1
        : _state.skunksAgainst;

    _persistence?.saveStats(
      gamesWon: gamesWon,
      gamesLost: gamesLost,
      skunksFor: skunksFor,
      skunksAgainst: skunksAgainst,
    );

    _state = _state.copyWith(
      gameOver: true,
      currentPhase: GamePhase.gameOver,
      gamesWon: gamesWon,
      gamesLost: gamesLost,
      skunksFor: skunksFor,
      skunksAgainst: skunksAgainst,
      showWinnerModal: true,
      winnerModalData: WinnerModalData(
        playerWon: playerWins,
        playerScore: _state.playerScore,
        opponentScore: _state.opponentScore,
        wasSkunk: skunked,
        gamesWon: gamesWon,
        gamesLost: gamesLost,
        skunksFor: skunksFor,
        skunksAgainst: skunksAgainst,
      ),
      gameStatus: playerWins ? 'You win!' : 'Opponent wins!',
    );
    notifyListeners();
  }

  void _maybeAutoplayOpponent() {
    if (_state.currentPhase != GamePhase.pegging || _state.isPlayerTurn) {
      return;
    }
    if (_state.pendingReset != null) {
      // Don't autoplay while showing pending reset dialog
      return;
    }
    // Don't check if opponent has played all cards here - they still need to say Go if needed
    if (_opponentAutoplayScheduled) {
      return;
    }
    _opponentAutoplayScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400)).then((_) {
      _opponentAutoplayScheduled = false;
      if (_state.isPlayerTurn || _state.currentPhase != GamePhase.pegging) {
        return;
      }
      final mgr = _peggingManager;
      if (mgr == null) {
        return;
      }
      final move = OpponentAI.choosePeggingCard(
        hand: _state.opponentHand,
        playedIndices: _state.opponentCardsPlayed,
        currentCount: mgr.peggingCount,
        peggingPile: mgr.peggingPile,
        opponentCardsRemaining: _state.playerHand.length - _state.playerCardsPlayed.length,
      );
      if (move == null) {
        debugPrint('[OPPONENT AI] No legal move - saying Go');
        handleGo(fromPlayer: false);
      } else {
        playCard(move.index, isPlayer: false);
      }
    });
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

/// Risk profiles for different game situations
enum RiskProfile {
  /// Way behind, need to take big risks
  desperate,

  /// Behind, need to be more aggressive
  aggressive,

  /// Close game, use standard strategy
  balanced,

  /// Ahead, minimize variance and opponent opportunities
  conservative,
}
