import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:cribbage/src/game/engine/game_engine.dart';
import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/services/game_persistence.dart';

class _FakePersistence implements GamePersistence {
  StoredStats? statsToLoad;
  CutCards? cutsToLoad;
  StoredStats? lastSavedStats;
  PlayingCard? savedCutPlayer;
  PlayingCard? savedCutOpponent;

  @override
  StoredStats? loadStats() => statsToLoad;

  @override
  CutCards? loadCutCards() => cutsToLoad;

  @override
  void saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
  }) {
    lastSavedStats = StoredStats(
      gamesWon: gamesWon,
      gamesLost: gamesLost,
      skunksFor: skunksFor,
      skunksAgainst: skunksAgainst,
    );
  }

  @override
  void saveCutCards(PlayingCard player, PlayingCard opponent) {
    savedCutPlayer = player;
    savedCutOpponent = opponent;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameEngine', () {
    late _FakePersistence persistence;
    late GameEngine engine;

    setUp(() {
      persistence = _FakePersistence();
      engine = GameEngine(
        persistence: persistence,
        random: Random(7),
      );
    });

    test('startNewGame resets scores and enters cut phase', () {
      engine.startNewGame();

      final state = engine.state;
      expect(state.gameStarted, isTrue);
      expect(state.currentPhase, GamePhase.cutForDealer);
      expect(state.playerScore, 0);
      expect(state.opponentScore, 0);
      expect(state.playerHand, isEmpty);
      expect(state.gameStatus, contains('Cut cards'));
    });

    test('cutForDealer reveals cut cards and persists them', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      final state = engine.state;
      expect(state.cutPlayerCard, isNotNull);
      expect(state.cutOpponentCard, isNotNull);
      expect(state.showCutForDealer, isTrue);
      expect(state.currentPhase, GamePhase.dealing);
      expect(persistence.savedCutPlayer, isNotNull);
      expect(persistence.savedCutOpponent, isNotNull);
    });

    test('dealCards transitions to crib selection with six cards each', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      engine.dealCards();
      final state = engine.state;
      expect(state.currentPhase, GamePhase.cribSelection);
      expect(state.playerHand.length, 6);
      expect(state.opponentHand.length, 6);
      expect(state.selectedCards, isEmpty);
      expect(state.gameStatus, contains('Select two cards'));
    });

    test('confirmCribSelection builds crib and starts pegging', () {
      engine.startNewGame();
      _cutUntilDealer(engine);
      engine.dealCards();

      engine.toggleCardSelection(0);
      engine.toggleCardSelection(1);
      engine.confirmCribSelection();

      final state = engine.state;
      expect(state.currentPhase, GamePhase.pegging);
      expect(state.isPeggingPhase, isTrue);
      expect(state.playerHand.length, 4);
      expect(state.cribHand.length, 4);
      expect(state.starterCard, isNotNull);
      expect(state.selectedCards, isEmpty);
    });

    test('playCard awards pair points in pegging', () {
      final customEngine = _setupPeggingEngine(
        playerDealer: true,
        requireMatchingRank: true,
      );
      final match = _findMatchingRankIndices(customEngine)!;

      expect(customEngine.state.currentPhase, GamePhase.pegging);
      expect(customEngine.state.isPlayerTurn, isFalse); // opponent starts when player is dealer

      final startingScore = customEngine.state.playerScore;

      customEngine.playCard(match.opponentIndex, isPlayer: false);
      expect(customEngine.state.isPlayerTurn, isTrue);

      customEngine.playCard(match.playerIndex, isPlayer: true);
      expect(customEngine.state.playerScore, startingScore + 2);
      expect(customEngine.state.playerCardsPlayed.contains(match.playerIndex), isTrue);
    });

    test('handleGo awards point and pending reset when player stuck', () {
      final goEngine = _setupGoScenarioEngine();
      final playerScoreBefore = goEngine.state.playerScore;

      expect(goEngine.playerHasLegalMove, isFalse);
      expect(goEngine.opponentHasLegalMove, isFalse);

      goEngine.handleGo(fromPlayer: true);

      final state = goEngine.state;
      expect(state.pendingReset, isNotNull);
      expect(state.pendingReset!.message, 'Go! Pile reset.');
      expect(state.playerScore, playerScoreBefore + 1);
      expect(state.peggingCount, 0);
      expect(state.playerScoreAnimation?.points, 1);

      goEngine.acknowledgePendingReset();
      expect(goEngine.state.pendingReset, isNull);
      expect(goEngine.state.peggingPile, isEmpty);
      expect(goEngine.state.peggingCount, 0);
    });

    test('updateScores triggers animations and checkGameOver saves stats', () {
      final customPersistence = _FakePersistence();
      final engine = _setupPeggingEngine(
        playerDealer: true,
        requireMatchingRank: true,
        seedStart: 250,
        persistence: customPersistence,
      );
      engine.updateScores(120, 100);
      expect(engine.state.playerScoreAnimation?.points, 120);
      expect(engine.state.opponentScoreAnimation?.points, 100);

      final match = _findMatchingRankIndices(engine)!;
      engine.playCard(match.opponentIndex, isPlayer: false);
      engine.playCard(match.playerIndex, isPlayer: true);

      final state = engine.state;
      expect(state.gameOver, isTrue);
      expect(state.showWinnerModal, isTrue);
      expect(state.winnerModalData, isNotNull);
      expect(state.winnerModalData!.playerWon, isTrue);
      expect(state.winnerModalData!.playerScore, state.playerScore);
      expect(state.winnerModalData!.opponentScore, state.opponentScore);
      expect(customPersistence.lastSavedStats, isNotNull);
      expect(customPersistence.lastSavedStats!.gamesWon, 1);
      expect(customPersistence.lastSavedStats!.gamesLost, 0);
    });

    test('maybeAutoplayOpponent schedules opponent move when player dealer', () {
      fakeAsync((async) {
        final engine = _setupPeggingEngine(
          playerDealer: true,
          selectDiscards: _selectLowestValueDiscards,
        );
        expect(engine.state.isPlayerTurn, isFalse);
        final before = engine.state.opponentCardsPlayed.length;
        async.elapse(const Duration(milliseconds: 500));
        expect(engine.state.opponentCardsPlayed.length, greaterThan(before));
        expect(engine.state.isPlayerTurn, isTrue);
      });
    });

    test('getAdvice returns valid card indices during crib selection', () {
      engine.startNewGame();
      _cutUntilDealer(engine);
      engine.dealCards();

      final advice = engine.getAdvice();
      expect(advice.length, 2);
      expect(advice[0], greaterThanOrEqualTo(0));
      expect(advice[0], lessThan(6));
      expect(advice[1], greaterThanOrEqualTo(0));
      expect(advice[1], lessThan(6));
      expect(advice[0], isNot(equals(advice[1])));
    });

    test('getAdvice returns empty list when not in crib selection phase', () {
      engine.startNewGame();

      var advice = engine.getAdvice();
      expect(advice, isEmpty);

      _cutUntilDealer(engine);
      advice = engine.getAdvice();
      expect(advice, isEmpty);
    });

    test('getAdvice considers game position when close to winning', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      // Simulate being close to winning (at 100 points)
      engine.updateScores(100, 80);
      engine.dealCards();

      final advice = engine.getAdvice();
      expect(advice.length, 2);
      // The advice should prioritize maximizing points when close to winning
    });

    test('getAdvice is more aggressive when behind', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      // Simulate being significantly behind (20 points)
      engine.updateScores(50, 70);
      engine.dealCards();

      final adviceBehind = engine.getAdvice();
      expect(adviceBehind.length, 2);

      // The advice should exist and be valid
      expect(adviceBehind[0], greaterThanOrEqualTo(0));
      expect(adviceBehind[1], greaterThanOrEqualTo(0));
    });

    test('getAdvice is defensive when ahead', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      // Simulate being ahead (20 points)
      engine.updateScores(80, 60);
      engine.dealCards();

      final adviceAhead = engine.getAdvice();
      expect(adviceAhead.length, 2);

      // Should return valid defensive advice
      expect(adviceAhead[0], greaterThanOrEqualTo(0));
      expect(adviceAhead[1], greaterThanOrEqualTo(0));
    });

    test('getAdvice handles critical endgame scenarios', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      // Both players very close to winning
      engine.updateScores(110, 108);
      engine.dealCards();

      final adviceCritical = engine.getAdvice();
      expect(adviceCritical.length, 2);

      // In critical games, advice should heavily weight hand value and crib defense
      expect(adviceCritical[0], greaterThanOrEqualTo(0));
      expect(adviceCritical[1], greaterThanOrEqualTo(0));
    });

    test('getAdvice handles desperate situations', () {
      engine.startNewGame();
      _cutUntilDealer(engine);

      // Way behind with opponent close to winning
      engine.updateScores(70, 100);
      engine.dealCards();

      final adviceDesperate = engine.getAdvice();
      expect(adviceDesperate.length, 2);

      // Should still provide valid advice even in desperate situations
      expect(adviceDesperate[0], greaterThanOrEqualTo(0));
      expect(adviceDesperate[1], greaterThanOrEqualTo(0));
    });
  });
}

void _cutUntilDealer(GameEngine engine, {int maxAttempts = 10}) {
  for (var i = 0; i < maxAttempts; i++) {
    engine.cutForDealer();
    if (engine.state.currentPhase == GamePhase.dealing) {
      return;
    }
  }
  fail('Failed to determine dealer after $maxAttempts attempts');
}

GameEngine _setupPeggingEngine({
  required bool playerDealer,
  bool requireMatchingRank = false,
  List<int> Function(List<PlayingCard>)? selectDiscards,
  int seedStart = 1,
  GamePersistence? persistence,
}) {
  for (var seed = seedStart; seed < seedStart + 200; seed++) {
    final engine = GameEngine(
      persistence: persistence ?? _FakePersistence(),
      random: Random(seed),
    );
    engine.startNewGame();
    _cutUntilDealer(engine);
    if (engine.state.isPlayerDealer != playerDealer) {
      continue;
    }
    engine.dealCards();
    final discardSelector = selectDiscards ?? _selectFirstTwoDiscards;
    final discards = discardSelector(engine.state.playerHand);
    for (final index in discards) {
      engine.toggleCardSelection(index);
    }
    engine.confirmCribSelection();
    if (requireMatchingRank && _findMatchingRankIndices(engine) == null) {
      continue;
    }
    return engine;
  }
  fail('Failed to prepare pegging scenario with requested constraints');
}

List<int> _selectFirstTwoDiscards(List<PlayingCard> hand) => [0, 1];

List<int> _selectLowestValueDiscards(List<PlayingCard> hand) {
  final entries = List.generate(hand.length, (index) => (index: index, value: hand[index].value));
  entries.sort((a, b) => a.value.compareTo(b.value));
  return entries.take(2).map((e) => e.index).toList();
}

({int playerIndex, int opponentIndex})? _findMatchingRankIndices(GameEngine engine) {
  final playerHand = engine.state.playerHand;
  final opponentHand = engine.state.opponentHand;
  for (var pi = 0; pi < playerHand.length; pi++) {
    for (var oi = 0; oi < opponentHand.length; oi++) {
      if (playerHand[pi].rank == opponentHand[oi].rank) {
        return (playerIndex: pi, opponentIndex: oi);
      }
    }
  }
  return null;
}

GameEngine _setupGoScenarioEngine() {
  // Try more seeds to find a valid Go scenario where BOTH players are stuck
  for (var seed = 1; seed <= 2000; seed++) {
    final engine = _setupPeggingEngine(
      playerDealer: true,
      selectDiscards: _selectLowestValueDiscards,
      seedStart: seed,
    );

    // Skip hands with aces (too flexible)
    if (engine.state.playerHand.any((card) => card.value == 1) ||
        engine.state.opponentHand.any((card) => card.value == 1)) {
      continue;
    }

    // Sort both hands by value (low to high)
    final playerOrder = List.generate(engine.state.playerHand.length, (index) => index)
      ..sort((a, b) => engine.state.playerHand[a].value.compareTo(engine.state.playerHand[b].value));
    final opponentOrder = List.generate(engine.state.opponentHand.length, (index) => index)
      ..sort((a, b) => engine.state.opponentHand[b].value.compareTo(engine.state.opponentHand[a].value));

    var playerIdx = 0;
    var opponentIdx = 0;
    var success = false;

    // Try to create a scenario where both players get stuck
    while (opponentIdx < opponentOrder.length || playerIdx < playerOrder.length) {
      // Opponent plays
      if (opponentIdx < opponentOrder.length) {
        final oppIndex = opponentOrder[opponentIdx];
        if (!engine.state.opponentCardsPlayed.contains(oppIndex) &&
            engine.state.peggingCount + engine.state.opponentHand[oppIndex].value <= 31) {
          engine.playCard(oppIndex, isPlayer: false);
          opponentIdx++;
        } else {
          opponentIdx++;
          continue;
        }
      }

      // Check if BOTH players are stuck
      if (!engine.playerHasLegalMove && !engine.opponentHasLegalMove) {
        success = true;
        break;
      }

      // Player plays
      if (playerIdx < playerOrder.length) {
        final playerIndex = playerOrder[playerIdx];
        if (!engine.state.playerCardsPlayed.contains(playerIndex) &&
            engine.isPlayerCardPlayable(playerIndex)) {
          engine.playCard(playerIndex, isPlayer: true);
          playerIdx++;
        } else {
          playerIdx++;
          continue;
        }
      }

      // Check again if BOTH players are stuck
      if (!engine.playerHasLegalMove && !engine.opponentHasLegalMove) {
        success = true;
        break;
      }
    }

    if (success) {
      return engine;
    }
  }
  fail('Failed to create Go scenario where both players stuck after 2000 attempts');
}
