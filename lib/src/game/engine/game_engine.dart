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
        doubleSkunksFor: stats.doubleSkunksFor,
        doubleSkunksAgainst: stats.doubleSkunksAgainst,
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
      if (sanitizedPlayerName != names.playerName ||
          sanitizedOpponentName != names.opponentName) {
      }
      _state = _state.copyWith(
        playerName: sanitizedPlayerName,
        opponentName: sanitizedOpponentName,
      );
    }
    notifyListeners();
  }

  void startNewGame() {
    _peggingManager = null;
    _opponentAutoplayScheduled = false;
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
      cutDeck: const [],
      playerHasSelectedCutCard: false,
      isPlayerTurn: false,
      gameOver: false,
      showWinnerModal: false,
      clearWinnerModalData: true,
      handScores: const HandScores(),
      countingPhase: CountingPhase.none,
      playerCardsPlayed: const {},
      opponentCardsPlayed: const {},
      peggingCount: 0,
      peggingPile: const [],
      consecutiveGoes: 0,
      clearLastPlayerWhoPlayed: true,
      clearPendingReset: true,
      peggingCompletedRounds: const [],
      isOpponentActionInProgress: false,
      showCutCardDisplay: false,
      clearPlayerScoreAnimation: true,
      clearOpponentScoreAnimation: true,
    );
    notifyListeners();
    // Automatically initialize the cut deck
    cutForDealer();
  }

  void cutForDealer() {
    // Initialize the cut deck and show it to the user
    final deck = createDeck(random: _random);
    _state = _state.copyWith(
      cutDeck: deck,
      playerHasSelectedCutCard: false,
      cutPlayerCard: null,
      cutOpponentCard: null,
      gameStatus: 'Tap the deck to cut for dealer.',
    );
    notifyListeners();
  }

  void selectCutCard(int index) {
    if (_state.cutDeck.isEmpty || index < 0 || index >= _state.cutDeck.length) {
      return;
    }

    // Player selects their card
    final playerCut = _state.cutDeck[index];

    // Opponent selects a random card (different from player's card)
    final remainingIndices = List<int>.generate(_state.cutDeck.length, (i) => i)
        .where((i) => i != index)
        .toList();
    final opponentIndex =
        remainingIndices[_random.nextInt(remainingIndices.length)];
    final opponentCut = _state.cutDeck[opponentIndex];

    _state = _state.copyWith(
      cutPlayerCard: playerCut,
      cutOpponentCard: opponentCut,
      playerHasSelectedCutCard: true,
      showCutForDealer: true,
    );
    // Fire and forget - don't block UI on save
    unawaited(_persistence?.saveCutCards(playerCut, opponentCut));

    final dealer = dealerFromCut(playerCut, opponentCut);
    if (dealer == null) {
      _state =
          _state.copyWith(gameStatus: 'Tie! Cut again to determine dealer.');
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
    } else {
    }
    _state = _state.copyWith(selectedCards: selected);
    notifyListeners();
  }

  /// Returns the indices of the two cards the player should discard to the crib.
  List<int> getAdvice() {
    if (_state.currentPhase != GamePhase.cribSelection ||
        _state.playerHand.length != 6) {
      return [];
    }
    return OpponentAI.chooseCribIndices(
      hand: _state.playerHand,
      isDealer: _state.isPlayerDealer,
      playerScore: _state.playerScore,
      opponentScore: _state.opponentScore,
    );
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
    final opponentCribSet = opponentCrib.toSet();
    final opponentHand = _state.opponentHand
        .where((card) => !opponentCribSet.contains(card))
        .toList();
    crib.addAll(opponentCrib);

    final starter = _drawDeck.isNotEmpty ? _drawDeck.first : null;
    _drawDeck = _drawDeck.skip(1).toList();

    var playerScore = _state.playerScore;
    var opponentScore = _state.opponentScore;
    var status = 'Starter card: ${starter?.label ?? '?'}';
    ScoreAnimation? hisHeelsAnimation;
    if (starter?.rank == Rank.jack) {
      if (_state.isPlayerDealer) {
        playerScore += 2;
        status += '\nYou scored 2 for His Heels!';
        hisHeelsAnimation = ScoreAnimation(
          points: 2,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        opponentScore += 2;
        status += '\nOpponent scored 2 for His Heels!';
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
      isPlayerTurn: !_state.isPlayerDealer,
      peggingCount: 0,
      peggingPile: const [],
      playerCardsPlayed: const {},
      opponentCardsPlayed: const {},
      playerScore: playerScore,
      opponentScore: opponentScore,
      gameStatus: status +
          (_state.isPlayerDealer
              ? '\nOpponent plays first.'
              : '\nYour turn to play.'),
      playerScoreAnimation:
          hisHeelsAnimation?.isPlayer == true ? hisHeelsAnimation : null,
      opponentScoreAnimation:
          hisHeelsAnimation?.isPlayer == false ? hisHeelsAnimation : null,
    );
    notifyListeners();
    _maybeAutoplayOpponent();
  }

  void playCard(int cardIndex, {bool isPlayer = true}) {
    if (isPlayer &&
        (!_state.isPlayerTurn || _state.currentPhase != GamePhase.pegging)) {
      return;
    }
    final hand = isPlayer ? _state.playerHand : _state.opponentHand;
    final played =
        isPlayer ? _state.playerCardsPlayed : _state.opponentCardsPlayed;
    if (cardIndex < 0 ||
        cardIndex >= hand.length ||
        played.contains(cardIndex)) {
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

    final outcome = mgr.onPlay(card);
    final pileAfter = List<PlayingCard>.from(mgr.peggingPile);
    final countAfter = mgr.peggingCount;
    final points =
        CribbageScorer.pointsForPile(pileBeforePlay, countBeforePlay);

    var status = _state.gameStatus;
    var playerScore = _state.playerScore;
    var opponentScore = _state.opponentScore;
    ScoreAnimation? peggingAnimation;

    if (points.total > 0) {
      if (isPlayer) {
        playerScore += points.total;
        status += '\nYou scored ${points.total}.';
        peggingAnimation = ScoreAnimation(
          points: points.total,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        opponentScore += points.total;
        status += '\nOpponent scored ${points.total}.';
        peggingAnimation = ScoreAnimation(
          points: points.total,
          isPlayer: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    final updatedPlayed = Set<int>.from(played)..add(cardIndex);

    // Only update score animations if points were scored, otherwise preserve existing animations
    final stateUpdate = _state.copyWith(
      peggingCount: countAfter,
      peggingPile: pileAfter,
      isPlayerTurn: mgr.isPlayerTurn == Player.player,
      playerCardsPlayed: isPlayer ? updatedPlayed : _state.playerCardsPlayed,
      opponentCardsPlayed:
          isPlayer ? _state.opponentCardsPlayed : updatedPlayed,
      playerScore: playerScore,
      opponentScore: opponentScore,
      gameStatus: status,
      peggingCompletedRounds: List<PeggingRound>.from(mgr.completedRounds),
    );

    // Apply animation updates only if there are points to show
    _state = peggingAnimation != null
        ? stateUpdate.copyWith(
            playerScoreAnimation:
                peggingAnimation.isPlayer ? peggingAnimation : null,
            opponentScoreAnimation:
                !peggingAnimation.isPlayer ? peggingAnimation : null,
          )
        : stateUpdate;
    notifyListeners();

    if (outcome.reset != null && outcome.reset!.resetFor31) {
      _state = _state.copyWith(
        pendingReset: PendingResetState(
          pile: pileBeforePlay, // Use pile before reset, not after
          finalCount: 31,
          scoreAwarded: points.total,
          message: '31!',
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
    final opponentHasMove =
        fromPlayer ? _opponentHasLegalMove() : _playerHasLegalMove();
    final pileBeforeReset = List<PlayingCard>.from(mgr.peggingPile);
    final countBeforeReset = mgr.peggingCount;

    final reset = mgr.onGo(opponentHasLegalMove: opponentHasMove);
    if (reset != null) {
      var playerScore = _state.playerScore;
      var opponentScore = _state.opponentScore;
      var scoreAwarded = 0;
      ScoreAnimation? goAnimation;
      if (reset.goPointTo == Player.player) {
        playerScore += 1;
        scoreAwarded = 1;
        goAnimation = ScoreAnimation(
          points: 1,
          isPlayer: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else if (reset.goPointTo == Player.opponent) {
        opponentScore += 1;
        scoreAwarded = 1;
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
        peggingPile: List<PlayingCard>.from(mgr.peggingPile),
        peggingCount: mgr.peggingCount,
        peggingCompletedRounds: List<PeggingRound>.from(mgr.completedRounds),
        pendingReset: PendingResetState(
          pile: pileBeforeReset,
          finalCount: countBeforeReset,
          scoreAwarded: scoreAwarded,
          message: 'Go!',
        ),
        playerScoreAnimation:
            goAnimation?.isPlayer == true ? goAnimation : null,
        opponentScoreAnimation:
            goAnimation?.isPlayer == false ? goAnimation : null,
      );
      notifyListeners();
      _checkPeggingComplete();
      // Don't call _maybeAutoplayOpponent here - wait for acknowledgePendingReset
      return;
    } else {
      _state = _state.copyWith(
        isPlayerTurn: mgr.isPlayerTurn == Player.player,
      );
      notifyListeners();
    }
    _checkPeggingComplete();
    _maybeAutoplayOpponent();
  }

  void acknowledgePendingReset() {
    final shouldClearPegging = _state.currentPhase != GamePhase.handCounting;

    _state = _state.copyWith(
      clearPendingReset: true,
      peggingPile: shouldClearPegging
          ? const []
          : (_state.pendingReset?.pile ?? _state.peggingPile),
      peggingCount: shouldClearPegging
          ? 0
          : (_state.pendingReset?.finalCount ?? _state.peggingCount),
    );
    notifyListeners();
    _checkPeggingComplete();
    _maybeAutoplayOpponent();
  }

  void startHandCounting() {
    if (_state.currentPhase != GamePhase.handCounting) return;

    final starter = _state.starterCard;
    if (starter == null) return;

    // Clear pegging history and pile now that user is moving to hand counting
    final mgr = _peggingManager;
    if (mgr != null) {
      mgr.completedRounds.clear();
      mgr.peggingPile.clear();
    }

    final hand =
        _state.isPlayerDealer ? _state.opponentHand : _state.playerHand;
    final breakdown =
        CribbageScorer.scoreHandWithBreakdown(hand, starter, false);

    // Set state with breakdown BEFORE showing dialog.
    // DON'T update scores or create animations yet — wait for user to click Continue.
    _state = _state.copyWith(
      peggingPile: const [],
      peggingCount: 0,
      peggingCompletedRounds: const [],
      countingPhase: CountingPhase.nonDealer,
      handScores: _state.handScores.copyWith(
        nonDealerScore: breakdown.totalScore,
        nonDealerBreakdown: breakdown,
      ),
    );

    notifyListeners();
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
          if (nonDealerScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: nonDealerScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          playerScore += nonDealerScore;
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
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation:
                nonDealerAnimation != null && nonDealerAnimation.isPlayer
                    ? nonDealerAnimation
                    : null,
            opponentScoreAnimation:
                nonDealerAnimation != null && !nonDealerAnimation.isPlayer
                    ? nonDealerAnimation
                    : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Now calculate dealer phase and store breakdown (but don't apply score yet)
        final hand =
            _state.isPlayerDealer ? _state.playerHand : _state.opponentHand;
        final breakdown =
            CribbageScorer.scoreHandWithBreakdown(hand, starter, false);


        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            dealerScore: breakdown.totalScore,
            dealerBreakdown: breakdown,
          ),
          countingPhase: CountingPhase.dealer,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation:
              nonDealerAnimation != null && nonDealerAnimation.isPlayer
                  ? nonDealerAnimation
                  : null,
          opponentScoreAnimation:
              nonDealerAnimation != null && !nonDealerAnimation.isPlayer
                  ? nonDealerAnimation
                  : null,
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
          if (dealerScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: dealerScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += dealerScore;
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
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation:
                dealerAnimation != null && dealerAnimation.isPlayer
                    ? dealerAnimation
                    : null,
            opponentScoreAnimation:
                dealerAnimation != null && !dealerAnimation.isPlayer
                    ? dealerAnimation
                    : null,
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


        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            cribScore: breakdown.totalScore,
            cribBreakdown: breakdown,
          ),
          countingPhase: CountingPhase.crib,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation:
              dealerAnimation != null && dealerAnimation.isPlayer
                  ? dealerAnimation
                  : null,
          opponentScoreAnimation:
              dealerAnimation != null && !dealerAnimation.isPlayer
                  ? dealerAnimation
                  : null,
        );
        break;

      case CountingPhase.crib:
        // Apply crib score and create animation NOW (user clicked Continue)
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        final cribScore = _state.handScores.cribScore;
        ScoreAnimation? cribAnimation;

        if (_state.isPlayerDealer) {
          playerScore += cribScore;
          if (cribScore > 0) {
            cribAnimation = ScoreAnimation(
              points: cribScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += cribScore;
          if (cribScore > 0) {
            cribAnimation = ScoreAnimation(
              points: cribScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Complete counting phase
        _state = _state.copyWith(
          countingPhase: CountingPhase.completed,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: cribAnimation != null && cribAnimation.isPlayer
              ? cribAnimation
              : null,
          opponentScoreAnimation:
              cribAnimation != null && !cribAnimation.isPlayer
                  ? cribAnimation
                  : null,
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
          if (manualScore > 0) {
            nonDealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          playerScore += manualScore;
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
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation:
                nonDealerAnimation != null && nonDealerAnimation.isPlayer
                    ? nonDealerAnimation
                    : null,
            opponentScoreAnimation:
                nonDealerAnimation != null && !nonDealerAnimation.isPlayer
                    ? nonDealerAnimation
                    : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Calculate dealer hand breakdown for next phase
        final dealerHand =
            _state.isPlayerDealer ? _state.playerHand : _state.opponentHand;
        final dealerBreakdown =
            CribbageScorer.scoreHandWithBreakdown(dealerHand, starter, false);


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
          playerScoreAnimation:
              nonDealerAnimation != null && nonDealerAnimation.isPlayer
                  ? nonDealerAnimation
                  : null,
          opponentScoreAnimation:
              nonDealerAnimation != null && !nonDealerAnimation.isPlayer
                  ? nonDealerAnimation
                  : null,
        );
        break;

      case CountingPhase.dealer:
        // Apply manual dealer score
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        ScoreAnimation? dealerAnimation;

        if (_state.isPlayerDealer) {
          playerScore += manualScore;
          if (manualScore > 0) {
            dealerAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += manualScore;
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
          _state = _state.copyWith(
            countingPhase: CountingPhase.completed,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerScoreAnimation:
                dealerAnimation != null && dealerAnimation.isPlayer
                    ? dealerAnimation
                    : null,
            opponentScoreAnimation:
                dealerAnimation != null && !dealerAnimation.isPlayer
                    ? dealerAnimation
                    : null,
          );
          _checkGameOver();
          notifyListeners();
          return;
        }

        // Calculate crib breakdown for next phase (crib is always counted as "in crib")
        final cribBreakdown = CribbageScorer.scoreHandWithBreakdown(
          _state.cribHand,
          starter,
          true,
        );


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
          playerScoreAnimation:
              dealerAnimation != null && dealerAnimation.isPlayer
                  ? dealerAnimation
                  : null,
          opponentScoreAnimation:
              dealerAnimation != null && !dealerAnimation.isPlayer
                  ? dealerAnimation
                  : null,
        );
        break;

      case CountingPhase.crib:
        // Apply manual crib score
        var playerScore = _state.playerScore;
        var opponentScore = _state.opponentScore;
        ScoreAnimation? cribAnimation;

        if (_state.isPlayerDealer) {
          playerScore += manualScore;
          if (manualScore > 0) {
            cribAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: true,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } else {
          opponentScore += manualScore;
          if (manualScore > 0) {
            cribAnimation = ScoreAnimation(
              points: manualScore,
              isPlayer: false,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Complete counting phase
        _state = _state.copyWith(
          handScores: _state.handScores.copyWith(
            cribScore: manualScore,
          ),
          countingPhase: CountingPhase.completed,
          playerScore: playerScore,
          opponentScore: opponentScore,
          playerScoreAnimation: cribAnimation != null && cribAnimation.isPlayer
              ? cribAnimation
              : null,
          opponentScoreAnimation:
              cribAnimation != null && !cribAnimation.isPlayer
                  ? cribAnimation
                  : null,
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
    // Fire and forget - don't block UI on save
    unawaited(
      _persistence?.savePlayerNames(
        playerName: _state.playerName,
        opponentName: _state.opponentName,
      ),
    );
    notifyListeners();
  }

  void updateScores(int newPlayerScore, int newOpponentScore) {

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
    if (_state.currentPhase != GamePhase.pegging ||
        index < 0 ||
        index >= _state.playerHand.length) {
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
    if (_state.playerCardsPlayed.length == 4 &&
        _state.opponentCardsPlayed.length == 4) {
      if (_state.pendingReset != null) {
        return;
      }

      final mgr = _peggingManager;
      final finalPile = mgr != null
          ? List<PlayingCard>.from(mgr.peggingPile)
          : <PlayingCard>[];
      final finalCount = mgr?.peggingCount ?? 0;
      final hasLastPileDialog = finalPile.isNotEmpty && finalCount > 0;

      // Award 1 point for last card if count is not 31
      // (If count is 31, the 2 points for 31 were already awarded)
      var playerScore = _state.playerScore;
      var opponentScore = _state.opponentScore;
      var status = _state.gameStatus;
      ScoreAnimation? lastCardAnimation;

      var scoreAwarded = 0;
      if (mgr != null && finalCount > 0 && finalCount != 31) {
        // Last player who played gets 1 point for last card
        if (mgr.lastPlayerWhoPlayed == Player.player) {
          playerScore += 1;
          status += '\nYou scored 1 for last card.';
          scoreAwarded = 1;
          lastCardAnimation = ScoreAnimation(
            points: 1,
            isPlayer: true,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        } else if (mgr.lastPlayerWhoPlayed == Player.opponent) {
          opponentScore += 1;
          status += '\nOpponent scored 1 for last card.';
          scoreAwarded = 1;
          lastCardAnimation = ScoreAnimation(
            points: 1,
            isPlayer: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }

      // Only update animations if last card scored, otherwise preserve existing animations
      final stateUpdate = _state.copyWith(
        currentPhase: GamePhase.handCounting,
        gameStatus: '$status\nPegging complete. Count hands.',
        isPlayerTurn: false,
        playerScore: playerScore,
        opponentScore: opponentScore,
        pendingReset: hasLastPileDialog
            ? PendingResetState(
                pile: finalPile,
                finalCount: finalCount,
                scoreAwarded: scoreAwarded,
                message: 'Last card',
              )
            : null,
      );

      if (hasLastPileDialog && mgr != null) {
        mgr.peggingPile.clear();
        mgr.peggingCount = 0;
        mgr.lastPlayerWhoPlayed = null;
      }

      _state = lastCardAnimation != null
          ? stateUpdate.copyWith(
              playerScoreAnimation:
                  lastCardAnimation.isPlayer ? lastCardAnimation : null,
              opponentScoreAnimation:
                  !lastCardAnimation.isPlayer ? lastCardAnimation : null,
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

    // Check for skunk (< 91) and double skunk (< 61)
    final doubleSkunk = loserScore < 61;
    final skunk = loserScore < 91;

    if (doubleSkunk) {
    } else if (skunk) {
    }

    final gamesWon = playerWins ? _state.gamesWon + 1 : _state.gamesWon;
    final gamesLost = playerWins ? _state.gamesLost : _state.gamesLost + 1;

    // Track regular skunks (includes double skunks in the count)
    final skunksFor =
        playerWins && skunk ? _state.skunksFor + 1 : _state.skunksFor;
    final skunksAgainst =
        !playerWins && skunk ? _state.skunksAgainst + 1 : _state.skunksAgainst;

    // Track double skunks separately
    final doubleSkunksFor = playerWins && doubleSkunk
        ? _state.doubleSkunksFor + 1
        : _state.doubleSkunksFor;
    final doubleSkunksAgainst = !playerWins && doubleSkunk
        ? _state.doubleSkunksAgainst + 1
        : _state.doubleSkunksAgainst;
    // Fire and forget - don't block UI on save
    unawaited(
      _persistence?.saveStats(
        gamesWon: gamesWon,
        gamesLost: gamesLost,
        skunksFor: skunksFor,
        skunksAgainst: skunksAgainst,
        doubleSkunksFor: doubleSkunksFor,
        doubleSkunksAgainst: doubleSkunksAgainst,
      ),
    );

    _state = _state.copyWith(
      gameOver: true,
      currentPhase: GamePhase.gameOver,
      gamesWon: gamesWon,
      gamesLost: gamesLost,
      skunksFor: skunksFor,
      skunksAgainst: skunksAgainst,
      doubleSkunksFor: doubleSkunksFor,
      doubleSkunksAgainst: doubleSkunksAgainst,
      showWinnerModal: true,
      winnerModalData: WinnerModalData(
        playerWon: playerWins,
        playerScore: _state.playerScore,
        opponentScore: _state.opponentScore,
        wasSkunk: skunk,
        wasDoubleSkunk: doubleSkunk,
        gamesWon: gamesWon,
        gamesLost: gamesLost,
        skunksFor: skunksFor,
        skunksAgainst: skunksAgainst,
        doubleSkunksFor: doubleSkunksFor,
        doubleSkunksAgainst: doubleSkunksAgainst,
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

    // Capture current state snapshot for validation after delay
    final expectedPhase = _state.currentPhase;
    final expectedTurn = _state.isPlayerTurn;
    final expectedPendingReset = _state.pendingReset;
    _opponentAutoplayScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400)).then((_) {
      _opponentAutoplayScheduled = false;

      // Comprehensive state validation - ensure state hasn't changed during delay
      if (_state.currentPhase != expectedPhase) {
        return;
      }
      if (_state.isPlayerTurn != expectedTurn) {
        return;
      }
      if (_state.pendingReset != expectedPendingReset) {
        return;
      }
      if (_state.currentPhase != GamePhase.pegging || _state.isPlayerTurn) {
        return;
      }
      if (_state.pendingReset != null) {
        return;
      }

      final mgr = _peggingManager;
      if (mgr == null) {
        return;
      }

      // Final validation: ensure turn is still opponent's
      if (mgr.isPlayerTurn != Player.opponent) {
        return;
      }
      final move = OpponentAI.choosePeggingCard(
        hand: _state.opponentHand,
        playedIndices: _state.opponentCardsPlayed,
        currentCount: mgr.peggingCount,
        peggingPile: mgr.peggingPile,
        opponentCardsRemaining:
            _state.playerHand.length - _state.playerCardsPlayed.length,
      );
      if (move == null) {
        handleGo(fromPlayer: false);
      } else {
        playCard(move.index, isPlayer: false);
      }
    });
  }
}

