import 'package:flutter/foundation.dart';

import '../models/card.dart';
import 'deal_utils.dart';

class PeggingRound {
  PeggingRound({
    required this.cards,
    required this.finalCount,
    required this.endReason,
  });

  final List<PlayingCard> cards;
  final int finalCount;
  final String endReason;
}

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
  final List<PeggingRound> completedRounds = [];

  PlayOutcome onPlay(PlayingCard card) {
    debugPrint('[PEGGING MGR] onPlay: ${card.label} (value=${card.value}), current count=$peggingCount');
    if (peggingCount + card.value > 31) {
      debugPrint('[PEGGING MGR ERROR] Illegal play! ${card.label} would exceed 31 (current=$peggingCount, card=${card.value})');
      throw ArgumentError('Illegal play that exceeds 31');
    }
    peggingPile.add(card);
    peggingCount += card.value;
    lastPlayerWhoPlayed = isPlayerTurn;
    consecutiveGoes = 0;
    debugPrint('[PEGGING MGR] New count: $peggingCount, pile size: ${peggingPile.length}');

    if (peggingCount == 31) {
      debugPrint('[PEGGING MGR] Count reached 31! Performing reset...');
      final reset = _performReset(resetFor31: true);
      return PlayOutcome(reset: reset);
    }

    isPlayerTurn = _other(isPlayerTurn);
    debugPrint('[PEGGING MGR] Turn switched to: ${isPlayerTurn == Player.player ? "Player" : "Opponent"}');
    return PlayOutcome();
  }

  SubRoundReset? onGo({required bool opponentHasLegalMove}) {
    debugPrint('[PEGGING MGR] onGo called: consecutiveGoes=$consecutiveGoes, opponentHasMove=$opponentHasLegalMove');
    consecutiveGoes += 1;
    if (!opponentHasLegalMove) {
      debugPrint('[PEGGING MGR] Opponent has no legal move - performing Go reset');
      return _performReset(resetFor31: false);
    }
    isPlayerTurn = _other(isPlayerTurn);
    debugPrint('[PEGGING MGR] Opponent has legal move, turn switched to: ${isPlayerTurn == Player.player ? "Player" : "Opponent"}');
    return null;
  }

  SubRoundReset _performReset({required bool resetFor31}) {
    final awardTo = resetFor31 ? null : lastPlayerWhoPlayed;
    final last = lastPlayerWhoPlayed;

    debugPrint('[PEGGING MGR] Performing reset: reason=${resetFor31 ? "31" : "Go"}, finalCount=$peggingCount');
    debugPrint('[PEGGING MGR] Go point awarded to: ${awardTo == Player.player ? "Player" : (awardTo == Player.opponent ? "Opponent" : "None (31)")}');

    // Save the completed round to history before clearing
    if (peggingPile.isNotEmpty) {
      final endReason = resetFor31 ? '31' : 'Go';
      debugPrint('[PEGGING MGR] Saving completed round to history: ${peggingPile.length} cards, reason=$endReason');
      completedRounds.add(
        PeggingRound(
          cards: List.from(peggingPile),
          finalCount: peggingCount,
          endReason: endReason,
        ),
      );
    }

    peggingCount = 0;
    peggingPile.clear();
    consecutiveGoes = 0;
    isPlayerTurn = last == Player.player ? Player.opponent : Player.player;
    lastPlayerWhoPlayed = null;
    debugPrint('[PEGGING MGR] Reset complete. Next player: ${isPlayerTurn == Player.player ? "Player" : "Opponent"}');
    return SubRoundReset(resetFor31: resetFor31, goPointTo: awardTo);
  }

  Player _other(Player value) => value == Player.player ? Player.opponent : Player.player;
}
