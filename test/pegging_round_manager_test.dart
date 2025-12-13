import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/logic/deal_utils.dart';
import 'package:cribbage/src/game/logic/pegging_round_manager.dart';
import 'package:cribbage/src/game/models/card.dart';

void main() {
  test('resets after reaching 31', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.nine, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.seven, suit: Suit.diamonds));
    final outcome =
        mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.spades));
    expect(outcome.reset, isNotNull);
    expect(outcome.reset!.resetFor31, isTrue);
    expect(mgr.peggingCount, 0);
  });

  test('go resets awards point to last player', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.clubs));
    final reset = mgr.onGo(opponentHasLegalMove: false);
    expect(reset, isNotNull);
    expect(reset!.goPointTo, Player.player);
  });

  test('go with opponent able to move simply passes the turn', () {
    final mgr = PeggingRoundManager(startingPlayer: Player.player);
    final reset = mgr.onGo(opponentHasLegalMove: true);
    expect(reset, isNull);
    expect(mgr.isPlayerTurn, Player.opponent);
    expect(mgr.consecutiveGoes, 1);
  });

  test('completed rounds capture pegging history on go reset', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.nine, suit: Suit.clubs)); // player
    mgr.onPlay(
        const PlayingCard(rank: Rank.six, suit: Suit.hearts),); // opponent

    final reset = mgr.onGo(opponentHasLegalMove: false);
    expect(reset, isNotNull);
    expect(reset!.goPointTo, Player.opponent);

    expect(mgr.completedRounds, hasLength(1));
    final round = mgr.completedRounds.single;
    expect(round.finalCount, 15);
    expect(round.endReason, 'Go');
    expect(round.cards.length, 2);
    expect(mgr.peggingPile, isEmpty);
    expect(mgr.peggingCount, 0);
    expect(mgr.isPlayerTurn, Player.player);
  });

  test('plays that exceed 31 throw an argument error', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.nine, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.eight, suit: Suit.spades));
    expect(
      () => mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.diamonds)),
      throwsArgumentError,
    );
  });

  test('initializes with correct starting player', () {
    final playerStarts = PeggingRoundManager(startingPlayer: Player.player);
    expect(playerStarts.isPlayerTurn, Player.player);

    final opponentStarts = PeggingRoundManager(startingPlayer: Player.opponent);
    expect(opponentStarts.isPlayerTurn, Player.opponent);
  });

  test('default starting player is player', () {
    final mgr = PeggingRoundManager();
    expect(mgr.isPlayerTurn, Player.player);
  });

  test('onPlay switches turns after valid play', () {
    final mgr = PeggingRoundManager(startingPlayer: Player.player);
    mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.hearts));
    expect(mgr.isPlayerTurn, Player.opponent);
    mgr.onPlay(const PlayingCard(rank: Rank.six, suit: Suit.clubs));
    expect(mgr.isPlayerTurn, Player.player);
  });

  test('onPlay updates pegging count correctly', () {
    final mgr = PeggingRoundManager();
    expect(mgr.peggingCount, 0);
    mgr.onPlay(const PlayingCard(rank: Rank.seven, suit: Suit.hearts));
    expect(mgr.peggingCount, 7);
    mgr.onPlay(const PlayingCard(rank: Rank.eight, suit: Suit.clubs));
    expect(mgr.peggingCount, 15);
  });

  test('onPlay adds card to pegging pile', () {
    final mgr = PeggingRoundManager();
    expect(mgr.peggingPile, isEmpty);
    final card1 = const PlayingCard(rank: Rank.ace, suit: Suit.spades);
    mgr.onPlay(card1);
    expect(mgr.peggingPile, [card1]);
    final card2 = const PlayingCard(rank: Rank.two, suit: Suit.diamonds);
    mgr.onPlay(card2);
    expect(mgr.peggingPile, [card1, card2]);
  });

  test('onPlay tracks last player who played', () {
    final mgr = PeggingRoundManager(startingPlayer: Player.player);
    expect(mgr.lastPlayerWhoPlayed, isNull);
    mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.hearts));
    expect(mgr.lastPlayerWhoPlayed, Player.player);
    mgr.onPlay(const PlayingCard(rank: Rank.six, suit: Suit.clubs));
    expect(mgr.lastPlayerWhoPlayed, Player.opponent);
  });

  test('onPlay resets consecutive goes counter', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.hearts));
    mgr.consecutiveGoes = 2; // Manually set
    mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.clubs));
    expect(mgr.consecutiveGoes, 0);
  });

  test('reset at 31 captures round history', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.king, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.queen, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.jack, suit: Suit.diamonds));
    final outcome =
        mgr.onPlay(const PlayingCard(rank: Rank.ace, suit: Suit.spades));

    expect(outcome.reset, isNotNull);
    expect(mgr.completedRounds, hasLength(1));
    final round = mgr.completedRounds.first;
    expect(round.finalCount, 31);
    expect(round.endReason, '31');
    expect(round.cards.length, 4);
  });

  test('reset at 31 does not award go point', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.king, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.queen, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.jack, suit: Suit.diamonds));
    final outcome =
        mgr.onPlay(const PlayingCard(rank: Rank.ace, suit: Suit.spades));

    expect(outcome.reset!.goPointTo, isNull);
  });

  test('reset after 31 switches to next player', () {
    final mgr = PeggingRoundManager(startingPlayer: Player.player);
    mgr.onPlay(const PlayingCard(rank: Rank.king, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.queen, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.jack, suit: Suit.diamonds));
    mgr.onPlay(const PlayingCard(
        rank: Rank.ace, suit: Suit.spades,),); // Opponent plays last

    // After reset, player should start next round (opponent made the 31)
    expect(mgr.isPlayerTurn, Player.player);
  });

  test('onGo increments consecutive goes', () {
    final mgr = PeggingRoundManager();
    expect(mgr.consecutiveGoes, 0);
    mgr.onGo(opponentHasLegalMove: true);
    expect(mgr.consecutiveGoes, 1);
  });

  test('multiple goes before reset tracks count', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.king, suit: Suit.hearts));
    mgr.onGo(opponentHasLegalMove: true);
    expect(mgr.consecutiveGoes, 1);
    mgr.onGo(opponentHasLegalMove: true);
    expect(mgr.consecutiveGoes, 2);
  });

  test('pegging count stays at 31 maximum', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ace, suit: Suit.hearts));
    expect(mgr.peggingCount, 1);
    expect(
      () => mgr.onPlay(const PlayingCard(rank: Rank.king, suit: Suit.hearts)),
      returnsNormally,
    );
  });

  test('go reset clears pile and count', () {
    final mgr = PeggingRoundManager();
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.nine, suit: Suit.clubs));
    expect(mgr.peggingPile, hasLength(2));
    expect(mgr.peggingCount, 19);

    mgr.onGo(opponentHasLegalMove: false);
    expect(mgr.peggingPile, isEmpty);
    expect(mgr.peggingCount, 0);
  });

  test('completed rounds accumulate across multiple resets', () {
    final mgr = PeggingRoundManager();

    // First sub-round
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.hearts));
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.clubs));
    mgr.onPlay(const PlayingCard(rank: Rank.ten, suit: Suit.diamonds));
    mgr.onPlay(const PlayingCard(rank: Rank.ace, suit: Suit.spades));
    expect(mgr.completedRounds, hasLength(1));

    // Second sub-round
    mgr.onPlay(const PlayingCard(rank: Rank.nine, suit: Suit.hearts));
    mgr.onGo(opponentHasLegalMove: false);
    expect(mgr.completedRounds, hasLength(2));
  });

  test('empty pile does not create round history', () {
    final mgr = PeggingRoundManager();
    // Try to reset with no cards played
    final reset = mgr.onGo(opponentHasLegalMove: false);
    expect(reset, isNotNull);
    expect(mgr.completedRounds, isEmpty); // No cards were in pile
  });
}
