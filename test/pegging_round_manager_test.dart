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
}
