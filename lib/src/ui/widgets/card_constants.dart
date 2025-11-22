/// Card sizing constants for consistent card display across the app
///
/// Standard playing card aspect ratio is 2.5:3.5 (or 5:7)
/// All card sizes maintain this ratio for visual consistency
/// Sized to fit 6 cards comfortably on screen (6 cards × 52px + spacing = ~348px)
class CardConstants {
  /// Standard card width for player/opponent hands
  static const double cardWidth = 52.0;

  /// Standard card height for player/opponent hands (maintains 5:7 ratio)
  static const double cardHeight = 72.8;

  /// Card back width (opponent cards, face down)
  static const double cardBackWidth = 52.0;

  /// Card back height (opponent cards, face down)
  static const double cardBackHeight = 72.8;

  /// Small card width (for pegging/played cards)
  static const double smallCardWidth = 45.0;

  /// Small card height (for pegging/played cards)
  static const double smallCardHeight = 63.0;

  /// Border radius for card corners
  static const double cardBorderRadius = 6.0;

  /// Standard border width for unselected cards
  static const double cardBorderWidth = 2.0;

  /// Selected card border width
  static const double selectedCardBorderWidth = 3.5;

  /// Horizontal spacing between cards
  static const double cardHorizontalSpacing = 3.0;

  /// Player hand container height (card height + padding)
  static const double playerHandHeight = 100.0;

  /// Opponent hand container height (card height + padding)
  static const double opponentHandHeight = 90.0;

  CardConstants._(); // Private constructor to prevent instantiation
}
