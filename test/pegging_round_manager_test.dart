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
    final outcome = mgr.onPlay(const PlayingCard(rank: Rank.five, suit: Suit.spades));
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
    mgr.onPlay(const PlayingCard(rank: Rank.six, suit: Suit.hearts)); // opponent

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
}
