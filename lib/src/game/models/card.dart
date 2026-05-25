import 'dart:math';

enum Player { player, opponent }

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

extension RankDisplay on Rank {
  String get label => switch (this) {
        Rank.ace => 'A',
        Rank.two => '2',
        Rank.three => '3',
        Rank.four => '4',
        Rank.five => '5',
        Rank.six => '6',
        Rank.seven => '7',
        Rank.eight => '8',
        Rank.nine => '9',
        Rank.ten => '10',
        Rank.jack => 'J',
        Rank.queen => 'Q',
        Rank.king => 'K',
      };
}

extension SuitDisplay on Suit {
  String get label => switch (this) {
        Suit.spades => '♠',
        Suit.hearts => '♥',
        Suit.diamonds => '♦',
        Suit.clubs => '♣',
      };
}

class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  final Rank rank;
  final Suit suit;

  int get value => switch (rank) {
        Rank.ace => 1,
        Rank.two => 2,
        Rank.three => 3,
        Rank.four => 4,
        Rank.five => 5,
        Rank.six => 6,
        Rank.seven => 7,
        Rank.eight => 8,
        Rank.nine => 9,
        Rank.ten || Rank.jack || Rank.queen || Rank.king => 10,
      };

  String get label => '${rank.label}${suit.label}';

  String encode() => '${rank.index}|${suit.index}';

  static PlayingCard decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 2) {
      return const PlayingCard(rank: Rank.ace, suit: Suit.spades);
    }
    final rankIndex = int.tryParse(parts[0]) ?? 0;
    final suitIndex = int.tryParse(parts[1]) ?? 0;
    return PlayingCard(
      rank: Rank.values[rankIndex.clamp(0, Rank.values.length - 1)],
      suit: Suit.values[suitIndex.clamp(0, Suit.values.length - 1)],
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard && other.rank == rank && other.suit == suit;
  }

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;
}

List<PlayingCard> createDeck({Random? random}) {
  final deck = [
    for (final suit in Suit.values)
      for (final rank in Rank.values)
        PlayingCard(rank: rank, suit: suit),
  ];
  deck.shuffle(random);
  return deck;
}
