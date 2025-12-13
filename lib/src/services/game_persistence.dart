import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/models/card.dart';

class StoredStats {
  const StoredStats({
    required this.gamesWon,
    required this.gamesLost,
    required this.skunksFor,
    required this.skunksAgainst,
    required this.doubleSkunksFor,
    required this.doubleSkunksAgainst,
  });

  final int gamesWon;
  final int gamesLost;
  final int skunksFor;
  final int skunksAgainst;
  final int doubleSkunksFor;
  final int doubleSkunksAgainst;
}

class CutCards {
  const CutCards({required this.player, required this.opponent});

  final PlayingCard player;
  final PlayingCard opponent;
}

class PlayerNames {
  const PlayerNames({required this.playerName, required this.opponentName});

  final String playerName;
  final String opponentName;
}

abstract class GamePersistence {
  StoredStats? loadStats();
  Future<void> saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
    required int doubleSkunksFor,
    required int doubleSkunksAgainst,
  });

  CutCards? loadCutCards();
  Future<void> saveCutCards(PlayingCard player, PlayingCard opponent);

  PlayerNames? loadPlayerNames();
  Future<void> savePlayerNames({
    required String playerName,
    required String opponentName,
  });
}

class SharedPrefsPersistence implements GamePersistence {
  SharedPrefsPersistence(this._prefs);

  final SharedPreferences _prefs;

  static const _gamesWonKey = 'gamesWon';
  static const _gamesLostKey = 'gamesLost';
  static const _skunksForKey = 'skunksFor';
  static const _skunksAgainstKey = 'skunksAgainst';
  static const _doubleSkunksForKey = 'doubleSkunksFor';
  static const _doubleSkunksAgainstKey = 'doubleSkunksAgainst';
  static const _playerCutKey = 'playerCut';
  static const _opponentCutKey = 'opponentCut';
  static const _playerNameKey = 'playerName';
  static const _opponentNameKey = 'opponentName';

  @override
  StoredStats? loadStats() {
    return StoredStats(
      gamesWon: _prefs.getInt(_gamesWonKey) ?? 0,
      gamesLost: _prefs.getInt(_gamesLostKey) ?? 0,
      skunksFor: _prefs.getInt(_skunksForKey) ?? 0,
      skunksAgainst: _prefs.getInt(_skunksAgainstKey) ?? 0,
      doubleSkunksFor: _prefs.getInt(_doubleSkunksForKey) ?? 0,
      doubleSkunksAgainst: _prefs.getInt(_doubleSkunksAgainstKey) ?? 0,
    );
  }

  @override
  Future<void> saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
    required int doubleSkunksFor,
    required int doubleSkunksAgainst,
  }) async {
    debugPrint(
      '[PERSISTENCE] Saving stats: Won=$gamesWon, Lost=$gamesLost, Skunks=$skunksFor/$skunksAgainst, DoubleSkunks=$doubleSkunksFor/$doubleSkunksAgainst',
    );
    try {
      await Future.wait([
        _prefs.setInt(_gamesWonKey, gamesWon),
        _prefs.setInt(_gamesLostKey, gamesLost),
        _prefs.setInt(_skunksForKey, skunksFor),
        _prefs.setInt(_skunksAgainstKey, skunksAgainst),
        _prefs.setInt(_doubleSkunksForKey, doubleSkunksFor),
        _prefs.setInt(_doubleSkunksAgainstKey, doubleSkunksAgainst),
      ]);
      debugPrint('[PERSISTENCE] Stats saved successfully');
    } catch (e) {
      debugPrint('[PERSISTENCE ERROR] Failed to save stats: $e');
    }
  }

  @override
  CutCards? loadCutCards() {
    final player = _prefs.getString(_playerCutKey);
    final opponent = _prefs.getString(_opponentCutKey);
    if (player == null || opponent == null) {
      return null;
    }
    return CutCards(
      player: PlayingCard.decode(player),
      opponent: PlayingCard.decode(opponent),
    );
  }

  @override
  Future<void> saveCutCards(PlayingCard player, PlayingCard opponent) async {
    debugPrint(
      '[PERSISTENCE] Saving cut cards: Player=${player.label}, Opponent=${opponent.label}',
    );
    try {
      await Future.wait([
        _prefs.setString(_playerCutKey, player.encode()),
        _prefs.setString(_opponentCutKey, opponent.encode()),
      ]);
      debugPrint('[PERSISTENCE] Cut cards saved successfully');
    } catch (e) {
      debugPrint('[PERSISTENCE ERROR] Failed to save cut cards: $e');
    }
  }

  @override
  PlayerNames? loadPlayerNames() {
    final playerName = _prefs.getString(_playerNameKey);
    final opponentName = _prefs.getString(_opponentNameKey);
    if (playerName == null || opponentName == null) {
      return null;
    }
    return PlayerNames(playerName: playerName, opponentName: opponentName);
  }

  @override
  Future<void> savePlayerNames({
    required String playerName,
    required String opponentName,
  }) async {
    debugPrint(
      '[PERSISTENCE] Saving player names: "$playerName" vs "$opponentName"',
    );
    try {
      await Future.wait([
        _prefs.setString(_playerNameKey, playerName),
        _prefs.setString(_opponentNameKey, opponentName),
      ]);
      debugPrint('[PERSISTENCE] Player names saved successfully');
    } catch (e) {
      debugPrint('[PERSISTENCE ERROR] Failed to save player names: $e');
    }
  }
}
