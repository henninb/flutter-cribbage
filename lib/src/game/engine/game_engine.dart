import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../logic/cribbage_scorer.dart';
import '../logic/deal_utils.dart';
import '../logic/opponent_ai.dart';
import '../logic/pegging_round_manager.dart';
import '../models/card.dart';
import '../../services/game_persistence.dart';
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
    _state = _state.copyWith(
      peggingCount: countAfter,
      peggingPile: pileAfter,
      isPlayerTurn: mgr.isPlayerTurn == Player.player,
      playerCardsPlayed: isPlayer ? updatedPlayed : _state.playerCardsPlayed,
      opponentCardsPlayed: isPlayer ? _state.opponentCardsPlayed : updatedPlayed,
      playerScore: playerScore,
      opponentScore: opponentScore,
      gameStatus: status,
      peggingManager: mgr,
      playerScoreAnimation: peggingAnimation?.isPlayer == true ? peggingAnimation : null,
      opponentScoreAnimation: peggingAnimation?.isPlayer == false ? peggingAnimation : null,
    );
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

    _state = _state.copyWith(
      playerScore: newPlayerScore,
      opponentScore: newOpponentScore,
      playerScoreAnimation: playerAnimation,
      opponentScoreAnimation: opponentAnimation,
    );
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

      _state = _state.copyWith(
        isPeggingPhase: false,
        currentPhase: GamePhase.handCounting,
        gameStatus: status + '\nPegging complete. Count hands.',
        isPlayerTurn: false,
        playerScore: playerScore,
        opponentScore: opponentScore,
        playerScoreAnimation: lastCardAnimation?.isPlayer == true ? lastCardAnimation : null,
        opponentScoreAnimation: lastCardAnimation?.isPlayer == false ? lastCardAnimation : null,
      );
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
