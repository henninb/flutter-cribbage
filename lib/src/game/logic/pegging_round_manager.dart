import '../models/card.dart';

typedef PeggingRound = ({
  List<PlayingCard> cards,
  int finalCount,
  String endReason,
});

typedef SubRoundReset = ({
  bool resetFor31,
  Player? goPointTo,
});

typedef PlayOutcome = ({SubRoundReset? reset});

class PeggingRoundManager {
  PeggingRoundManager({Player startingPlayer = Player.player})
      : activePlayer = startingPlayer;

  Player activePlayer;
  int peggingCount = 0;
  int consecutiveGoes = 0;
  Player? lastPlayerWhoPlayed;
  final List<PlayingCard> peggingPile = [];
  final List<PeggingRound> completedRounds = [];

  PlayOutcome onPlay(PlayingCard card) {
    if (peggingCount + card.value > 31) {
      throw ArgumentError('Illegal play that exceeds 31');
    }
    peggingPile.add(card);
    peggingCount += card.value;
    lastPlayerWhoPlayed = activePlayer;
    consecutiveGoes = 0;

    if (peggingCount == 31) {
      return (reset: _performReset(resetFor31: true));
    }

    activePlayer = _other(activePlayer);
    return (reset: null);
  }

  SubRoundReset? onGo({required bool opponentHasLegalMove}) {
    consecutiveGoes += 1;
    if (!opponentHasLegalMove) {
      return _performReset(resetFor31: false);
    }
    activePlayer = _other(activePlayer);
    return null;
  }

  SubRoundReset _performReset({required bool resetFor31}) {
    final awardTo = resetFor31 ? null : lastPlayerWhoPlayed;
    final last = lastPlayerWhoPlayed;

    if (peggingPile.isNotEmpty) {
      completedRounds.add((
        cards: List.from(peggingPile),
        finalCount: peggingCount,
        endReason: resetFor31 ? '31' : 'Go',
      ),);
    }

    peggingCount = 0;
    peggingPile.clear();
    consecutiveGoes = 0;
    activePlayer = last == Player.player ? Player.opponent : Player.player;
    lastPlayerWhoPlayed = null;
    return (resetFor31: resetFor31, goPointTo: awardTo);
  }

  Player _other(Player value) =>
      value == Player.player ? Player.opponent : Player.player;
}
