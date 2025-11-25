import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/services/game_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsPersistence', () {
    late SharedPreferences prefs;
    late SharedPrefsPersistence persistence;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      persistence = SharedPrefsPersistence(prefs);
    });

    test('loadStats defaults to zeros and saveStats persists values', () async {
      final defaults = persistence.loadStats();
      expect(defaults, isNotNull);
      expect(defaults!.gamesWon, 0);
      expect(defaults.gamesLost, 0);
      expect(defaults.skunksFor, 0);
      expect(defaults.skunksAgainst, 0);
      expect(defaults.doubleSkunksFor, 0);
      expect(defaults.doubleSkunksAgainst, 0);

      persistence.saveStats(
        gamesWon: 5,
        gamesLost: 2,
        skunksFor: 1,
        skunksAgainst: 3,
        doubleSkunksFor: 1,
        doubleSkunksAgainst: 0,
      );

      final loaded = persistence.loadStats();
      expect(loaded, isNotNull);
      expect(loaded!.gamesWon, 5);
      expect(loaded.gamesLost, 2);
      expect(loaded.skunksFor, 1);
      expect(loaded.skunksAgainst, 3);
      expect(loaded.doubleSkunksFor, 1);
      expect(loaded.doubleSkunksAgainst, 0);
    });

    test('cut cards round-trip through save and load', () {
      const playerCard = PlayingCard(rank: Rank.queen, suit: Suit.spades);
      const opponentCard = PlayingCard(rank: Rank.three, suit: Suit.hearts);

      persistence.saveCutCards(playerCard, opponentCard);

      final loaded = persistence.loadCutCards();
      expect(loaded, isNotNull);
      expect(loaded!.player, playerCard);
      expect(loaded.opponent, opponentCard);
    });

    test('loadCutCards returns null when storage missing entries', () async {
      await prefs.setString('playerCut', PlayingCard(rank: Rank.five, suit: Suit.clubs).encode());
      final loaded = persistence.loadCutCards();
      expect(loaded, isNull);
    });

    test('player names round-trip through save and load', () {
      persistence.savePlayerNames(playerName: 'Alice', opponentName: 'Bot');

      final names = persistence.loadPlayerNames();
      expect(names, isNotNull);
      expect(names!.playerName, 'Alice');
      expect(names.opponentName, 'Bot');
    });

    test('loadPlayerNames returns null when one side missing', () async {
      await prefs.setString('playerName', 'Solo');
      final names = persistence.loadPlayerNames();
      expect(names, isNull);
    });
  });
}
