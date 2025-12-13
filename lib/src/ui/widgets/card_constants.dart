/// Card sizing constants for consistent card display across the app
///
/// Traditional playing card aspect ratio is 2.5:3.5 (width:height = 1:1.4)
/// All card sizes maintain this ratio for visual consistency and realism
/// Sized to fit 6 cards comfortably on screen with proper overlap
class CardConstants {
  /// Standard card width for player/opponent hands
  /// Sized for good readability on mobile screens
  static const double cardWidth = 60.0;

  /// Standard card height for player/opponent hands (maintains 2.5:3.5 ratio)
  /// height = width * 1.4
  static const double cardHeight = 84.0;

  /// Card back width (opponent cards, face down)
  static const double cardBackWidth = 60.0;

  /// Card back height (opponent cards, face down)
  static const double cardBackHeight = 84.0;

  /// Small card width (for pegging/played cards in pile)
  static const double smallCardWidth = 50.0;

  /// Small card height (for pegging/played cards)
  /// Maintains 2.5:3.5 ratio
  static const double smallCardHeight = 70.0;

  /// Border radius for card corners (proportional to card width)
  static const double cardBorderRadius = 6.0;

  /// Standard border width for unselected cards
  static const double cardBorderWidth = 1.5;

  /// Selected card border width
  static const double selectedCardBorderWidth = 3.0;

  /// Horizontal spacing between cards in hand
  static const double cardHorizontalSpacing = 2.0;

  /// Player hand container height (card height + padding)
  static const double playerHandHeight = 120.0;

  /// Opponent hand container height (card height + padding)
  static const double opponentHandHeight = 110.0;

  /// Active pegging card width (larger for better visibility)
  static const double activePeggingCardWidth = 60.0;

  /// Active pegging card height (maintains 2.5:3.5 ratio)
  static const double activePeggingCardHeight = 84.0;

  /// Overlap offset for fanned active pegging cards
  /// Shows approximately top 1/3 of each card (enough to see corner index)
  static const double peggingCardOverlap = 22.0;

  CardConstants._(); // Private constructor to prevent instantiation
}
