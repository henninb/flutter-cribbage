import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

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
