import '../models/card.dart';
import 'deal_utils.dart';

class SubRoundReset {
  SubRoundReset({required this.resetFor31, required this.goPointTo});

  final bool resetFor31;
  final Player? goPointTo;
}

class PlayOutcome {
  PlayOutcome({this.reset});

  final SubRoundReset? reset;
}

class PeggingRoundManager {
  PeggingRoundManager({Player startingPlayer = Player.player})
      : isPlayerTurn = startingPlayer;

  Player isPlayerTurn;
  int peggingCount = 0;
  int consecutiveGoes = 0;
  Player? lastPlayerWhoPlayed;
  final List<PlayingCard> peggingPile = [];

  PlayOutcome onPlay(PlayingCard card) {
    if (peggingCount + card.value > 31) {
      throw ArgumentError('Illegal play that exceeds 31');
    }
    peggingPile.add(card);
    peggingCount += card.value;
    lastPlayerWhoPlayed = isPlayerTurn;
    consecutiveGoes = 0;

    if (peggingCount == 31) {
      final reset = _performReset(resetFor31: true);
      return PlayOutcome(reset: reset);
    }

    isPlayerTurn = _other(isPlayerTurn);
    return PlayOutcome();
  }

  SubRoundReset? onGo({required bool opponentHasLegalMove}) {
    consecutiveGoes += 1;
    if (!opponentHasLegalMove) {
      return _performReset(resetFor31: false);
    }
    isPlayerTurn = _other(isPlayerTurn);
    return null;
  }

  SubRoundReset _performReset({required bool resetFor31}) {
    final awardTo = resetFor31 ? null : lastPlayerWhoPlayed;
    final last = lastPlayerWhoPlayed;
    peggingCount = 0;
    peggingPile.clear();
    consecutiveGoes = 0;
    isPlayerTurn = last == Player.player ? Player.opponent : Player.player;
    lastPlayerWhoPlayed = null;
    return SubRoundReset(resetFor31: resetFor31, goPointTo: awardTo);
  }

  Player _other(Player value) => value == Player.player ? Player.opponent : Player.player;
}
