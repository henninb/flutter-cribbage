import 'dart:math';

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

class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  final Rank rank;
  final Suit suit;

  int get value {
    switch (rank) {
      case Rank.ace:
        return 1;
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
    }
  }

  String get label => '${_rankLabel(rank)}${_suitLabel(suit)}';

  String encode() => '${rank.index}|${suit.index}';

  static PlayingCard decode(String raw) {
    final parts = raw.split('|');
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

String _rankLabel(Rank rank) {
  switch (rank) {
    case Rank.ace:
      return 'A';
    case Rank.two:
      return '2';
    case Rank.three:
      return '3';
    case Rank.four:
      return '4';
    case Rank.five:
      return '5';
    case Rank.six:
      return '6';
    case Rank.seven:
      return '7';
    case Rank.eight:
      return '8';
    case Rank.nine:
      return '9';
    case Rank.ten:
      return '10';
    case Rank.jack:
      return 'J';
    case Rank.queen:
      return 'Q';
    case Rank.king:
      return 'K';
  }
}

String _suitLabel(Suit suit) {
  switch (suit) {
    case Suit.spades:
      return '♠';
    case Suit.hearts:
      return '♥';
    case Suit.diamonds:
      return '♦';
    case Suit.clubs:
      return '♣';
  }
}

List<PlayingCard> createDeck({Random? random}) {
  final deck = <PlayingCard>[];
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      deck.add(PlayingCard(rank: rank, suit: suit));
    }
  }
  if (random != null) {
    deck.shuffle(random);
  } else {
    deck.shuffle();
  }
  return deck;
}
