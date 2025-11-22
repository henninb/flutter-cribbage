import '../models/card.dart';

enum Player { player, opponent }

class DealResult {
  DealResult({
    required this.playerHand,
    required this.opponentHand,
    required this.remainingDeck,
  });

  final List<PlayingCard> playerHand;
  final List<PlayingCard> opponentHand;
  final List<PlayingCard> remainingDeck;
}

DealResult dealSixToEach(List<PlayingCard> deck, bool playerIsDealer) {
  final player = <PlayingCard>[];
  final opponent = <PlayingCard>[];
  final drawDeck = List<PlayingCard>.from(deck);
  for (var i = 0; i < 6; i++) {
    if (playerIsDealer) {
      opponent.add(drawDeck.removeAt(0));
      player.add(drawDeck.removeAt(0));
    } else {
      player.add(drawDeck.removeAt(0));
      opponent.add(drawDeck.removeAt(0));
    }
  }
  return DealResult(
    playerHand: player,
    opponentHand: opponent,
    remainingDeck: drawDeck,
  );
}

Player? dealerFromCut(PlayingCard playerCut, PlayingCard opponentCut) {
  if (playerCut.rank.index == opponentCut.rank.index) {
    return null;
  }
  return playerCut.rank.index < opponentCut.rank.index
      ? Player.player
      : Player.opponent;
}
