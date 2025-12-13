import 'package:flutter/foundation.dart';

import '../logic/cribbage_scorer.dart';
import '../logic/deal_utils.dart';
import '../logic/pegging_round_manager.dart';
import '../models/card.dart';

enum GamePhase {
  setup,
  cutForDealer,
  dealing,
  cribSelection,
  pegging,
  handCounting,
  gameOver,
}

enum CountingPhase { none, nonDealer, dealer, crib, completed }

@immutable
class HandScores {
  const HandScores({
    this.nonDealerScore = 0,
    this.dealerScore = 0,
    this.cribScore = 0,
    this.nonDealerBreakdown,
    this.dealerBreakdown,
    this.cribBreakdown,
  });

  final int nonDealerScore;
  final int dealerScore;
  final int cribScore;
  final DetailedScoreBreakdown? nonDealerBreakdown;
  final DetailedScoreBreakdown? dealerBreakdown;
  final DetailedScoreBreakdown? cribBreakdown;

  HandScores copyWith({
    int? nonDealerScore,
    int? dealerScore,
    int? cribScore,
    DetailedScoreBreakdown? nonDealerBreakdown,
    DetailedScoreBreakdown? dealerBreakdown,
    DetailedScoreBreakdown? cribBreakdown,
  }) {
    return HandScores(
      nonDealerScore: nonDealerScore ?? this.nonDealerScore,
      dealerScore: dealerScore ?? this.dealerScore,
      cribScore: cribScore ?? this.cribScore,
      nonDealerBreakdown: nonDealerBreakdown ?? this.nonDealerBreakdown,
      dealerBreakdown: dealerBreakdown ?? this.dealerBreakdown,
      cribBreakdown: cribBreakdown ?? this.cribBreakdown,
    );
  }
}

@immutable
class PendingResetState {
  const PendingResetState({
    required this.pile,
    required this.finalCount,
    required this.scoreAwarded,
    required this.message,
  });

  final List<PlayingCard> pile;
  final int finalCount;
  final int scoreAwarded;
  final String message;
}

@immutable
class WinnerModalData {
  const WinnerModalData({
    required this.playerWon,
    required this.playerScore,
    required this.opponentScore,
    required this.wasSkunk,
    required this.wasDoubleSkunk,
    required this.gamesWon,
    required this.gamesLost,
    required this.skunksFor,
    required this.skunksAgainst,
    required this.doubleSkunksFor,
    required this.doubleSkunksAgainst,
  });

  final bool playerWon;
  final int playerScore;
  final int opponentScore;
  final bool wasSkunk;
  final bool wasDoubleSkunk;
  final int gamesWon;
  final int gamesLost;
  final int skunksFor;
  final int skunksAgainst;
  final int doubleSkunksFor;
  final int doubleSkunksAgainst;
}

@immutable
class ScoreAnimation {
  const ScoreAnimation({
    required this.points,
    required this.isPlayer,
    required this.timestamp,
  });

  final int points;
  final bool isPlayer;
  final int timestamp;
}

@immutable
class GameState {
  const GameState({
    this.gameStarted = false,
    this.currentPhase = GamePhase.setup,
    this.gameOver = false,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.skunksFor = 0,
    this.skunksAgainst = 0,
    this.doubleSkunksFor = 0,
    this.doubleSkunksAgainst = 0,
    this.isPlayerDealer = false,
    this.playerHand = const [],
    this.opponentHand = const [],
    this.cribHand = const [],
    this.starterCard,
    this.selectedCards = const {},
    this.cutPlayerCard,
    this.cutOpponentCard,
    this.showCutForDealer = false,
    this.cutDeck = const [],
    this.playerHasSelectedCutCard = false,
    this.isPeggingPhase = false,
    this.isPlayerTurn = false,
    this.peggingCount = 0,
    this.peggingPile = const [],
    this.playerCardsPlayed = const {},
    this.opponentCardsPlayed = const {},
    this.consecutiveGoes = 0,
    this.lastPlayerWhoPlayed,
    this.isInHandCountingPhase = false,
    this.countingPhase = CountingPhase.none,
    this.handScores = const HandScores(),
    this.gameStatus = '',
    this.isOpponentActionInProgress = false,
    this.pendingReset,
    this.showWinnerModal = false,
    this.winnerModalData,
    this.peggingManager,
    this.showCutCardDisplay = false,
    this.playerScoreAnimation,
    this.opponentScoreAnimation,
    this.playerName = 'You',
    this.opponentName = 'Opponent',
  });

  final bool gameStarted;
  final GamePhase currentPhase;
  final bool gameOver;
  final int playerScore;
  final int opponentScore;
  final int gamesWon;
  final int gamesLost;
  final int skunksFor;
  final int skunksAgainst;
  final int doubleSkunksFor;
  final int doubleSkunksAgainst;
  final bool isPlayerDealer;
  final List<PlayingCard> playerHand;
  final List<PlayingCard> opponentHand;
  final List<PlayingCard> cribHand;
  final PlayingCard? starterCard;
  final Set<int> selectedCards;
  final PlayingCard? cutPlayerCard;
  final PlayingCard? cutOpponentCard;
  final bool showCutForDealer;
  final List<PlayingCard> cutDeck;
  final bool playerHasSelectedCutCard;
  final bool isPeggingPhase;
  final bool isPlayerTurn;
  final int peggingCount;
  final List<PlayingCard> peggingPile;
  final Set<int> playerCardsPlayed;
  final Set<int> opponentCardsPlayed;
  final int consecutiveGoes;
  final Player? lastPlayerWhoPlayed;
  final bool isInHandCountingPhase;
  final CountingPhase countingPhase;
  final HandScores handScores;
  final String gameStatus;
  final bool isOpponentActionInProgress;
  final PendingResetState? pendingReset;
  final bool showWinnerModal;
  final WinnerModalData? winnerModalData;
  final PeggingRoundManager? peggingManager;
  final bool showCutCardDisplay;
  final ScoreAnimation? playerScoreAnimation;
  final ScoreAnimation? opponentScoreAnimation;
  final String playerName;
  final String opponentName;

  GameState copyWith({
    bool? gameStarted,
    GamePhase? currentPhase,
    bool? gameOver,
    int? playerScore,
    int? opponentScore,
    int? gamesWon,
    int? gamesLost,
    int? skunksFor,
    int? skunksAgainst,
    int? doubleSkunksFor,
    int? doubleSkunksAgainst,
    bool? isPlayerDealer,
    List<PlayingCard>? playerHand,
    List<PlayingCard>? opponentHand,
    List<PlayingCard>? cribHand,
    PlayingCard? starterCard,
    bool clearStarterCard = false,
    Set<int>? selectedCards,
    PlayingCard? cutPlayerCard,
    PlayingCard? cutOpponentCard,
    bool? showCutForDealer,
    List<PlayingCard>? cutDeck,
    bool? playerHasSelectedCutCard,
    bool? isPeggingPhase,
    bool? isPlayerTurn,
    int? peggingCount,
    List<PlayingCard>? peggingPile,
    Set<int>? playerCardsPlayed,
    Set<int>? opponentCardsPlayed,
    int? consecutiveGoes,
    Player? lastPlayerWhoPlayed,
    bool? isInHandCountingPhase,
    CountingPhase? countingPhase,
    HandScores? handScores,
    String? gameStatus,
    bool? isOpponentActionInProgress,
    PendingResetState? pendingReset,
    bool clearPendingReset = false,
    bool? showWinnerModal,
    WinnerModalData? winnerModalData,
    PeggingRoundManager? peggingManager,
    bool? showCutCardDisplay,
    ScoreAnimation? playerScoreAnimation,
    ScoreAnimation? opponentScoreAnimation,
    bool clearPlayerScoreAnimation = false,
    bool clearOpponentScoreAnimation = false,
    String? playerName,
    String? opponentName,
  }) {
    return GameState(
      gameStarted: gameStarted ?? this.gameStarted,
      currentPhase: currentPhase ?? this.currentPhase,
      gameOver: gameOver ?? this.gameOver,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      skunksFor: skunksFor ?? this.skunksFor,
      skunksAgainst: skunksAgainst ?? this.skunksAgainst,
      doubleSkunksFor: doubleSkunksFor ?? this.doubleSkunksFor,
      doubleSkunksAgainst: doubleSkunksAgainst ?? this.doubleSkunksAgainst,
      isPlayerDealer: isPlayerDealer ?? this.isPlayerDealer,
      playerHand: playerHand ?? this.playerHand,
      opponentHand: opponentHand ?? this.opponentHand,
      cribHand: cribHand ?? this.cribHand,
      starterCard: clearStarterCard ? null : (starterCard ?? this.starterCard),
      selectedCards: selectedCards ?? this.selectedCards,
      cutPlayerCard: cutPlayerCard ?? this.cutPlayerCard,
      cutOpponentCard: cutOpponentCard ?? this.cutOpponentCard,
      showCutForDealer: showCutForDealer ?? this.showCutForDealer,
      cutDeck: cutDeck ?? this.cutDeck,
      playerHasSelectedCutCard:
          playerHasSelectedCutCard ?? this.playerHasSelectedCutCard,
      isPeggingPhase: isPeggingPhase ?? this.isPeggingPhase,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      peggingCount: peggingCount ?? this.peggingCount,
      peggingPile: peggingPile ?? this.peggingPile,
      playerCardsPlayed: playerCardsPlayed ?? this.playerCardsPlayed,
      opponentCardsPlayed: opponentCardsPlayed ?? this.opponentCardsPlayed,
      consecutiveGoes: consecutiveGoes ?? this.consecutiveGoes,
      lastPlayerWhoPlayed: lastPlayerWhoPlayed ?? this.lastPlayerWhoPlayed,
      isInHandCountingPhase:
          isInHandCountingPhase ?? this.isInHandCountingPhase,
      countingPhase: countingPhase ?? this.countingPhase,
      handScores: handScores ?? this.handScores,
      gameStatus: gameStatus ?? this.gameStatus,
      isOpponentActionInProgress:
          isOpponentActionInProgress ?? this.isOpponentActionInProgress,
      pendingReset:
          clearPendingReset ? null : (pendingReset ?? this.pendingReset),
      showWinnerModal: showWinnerModal ?? this.showWinnerModal,
      winnerModalData: winnerModalData ?? this.winnerModalData,
      peggingManager: peggingManager ?? this.peggingManager,
      showCutCardDisplay: showCutCardDisplay ?? this.showCutCardDisplay,
      playerScoreAnimation: clearPlayerScoreAnimation
          ? null
          : (playerScoreAnimation ?? this.playerScoreAnimation),
      opponentScoreAnimation: clearOpponentScoreAnimation
          ? null
          : (opponentScoreAnimation ?? this.opponentScoreAnimation),
      playerName: playerName ?? this.playerName,
      opponentName: opponentName ?? this.opponentName,
    );
  }
}
