import 'package:shared_preferences/shared_preferences.dart';

import '../game/models/card.dart';

class StoredStats {
  const StoredStats({
    required this.gamesWon,
    required this.gamesLost,
    required this.skunksFor,
    required this.skunksAgainst,
  });

  final int gamesWon;
  final int gamesLost;
  final int skunksFor;
  final int skunksAgainst;
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
  void saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
  });

  CutCards? loadCutCards();
  void saveCutCards(PlayingCard player, PlayingCard opponent);

  PlayerNames? loadPlayerNames();
  void savePlayerNames({required String playerName, required String opponentName});
}

class SharedPrefsPersistence implements GamePersistence {
  SharedPrefsPersistence(this._prefs);

  final SharedPreferences _prefs;

  static const _gamesWonKey = 'gamesWon';
  static const _gamesLostKey = 'gamesLost';
  static const _skunksForKey = 'skunksFor';
  static const _skunksAgainstKey = 'skunksAgainst';
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
    );
  }

  @override
  void saveStats({
    required int gamesWon,
    required int gamesLost,
    required int skunksFor,
    required int skunksAgainst,
  }) {
    _prefs
      ..setInt(_gamesWonKey, gamesWon)
      ..setInt(_gamesLostKey, gamesLost)
      ..setInt(_skunksForKey, skunksFor)
      ..setInt(_skunksAgainstKey, skunksAgainst);
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
  void saveCutCards(PlayingCard player, PlayingCard opponent) {
    _prefs
      ..setString(_playerCutKey, player.encode())
      ..setString(_opponentCutKey, opponent.encode());
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
  void savePlayerNames({required String playerName, required String opponentName}) {
    _prefs
      ..setString(_playerNameKey, playerName)
      ..setString(_opponentNameKey, opponentName);
  }
}
