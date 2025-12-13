import 'package:flutter/material.dart';
import '../../game/models/card.dart';

/// Professional playing card widget with traditional design
/// Features:
/// - Corner indices (top-left and bottom-right)
/// - White background with proper shadows
/// - Traditional 2.5:3.5 aspect ratio
/// - Red/black suit colors
/// - Enhanced depth and realism
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double? height;
  final bool isSelected;
  final bool isPlayed;
  final bool isPlayable;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    required this.width,
    this.height,
    this.isSelected = false,
    this.isPlayed = false,
    this.isPlayable = true,
    this.onTap,
  });

  /// Calculate height based on traditional 2.5:3.5 ratio if not provided
  double get _height => height ?? (width * 1.4);

  /// Get suit color (red for hearts/diamonds, black for spades/clubs)
  Color get suitColor {
    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return const Color(0xFFD32F2F); // Rich red
      case Suit.spades:
      case Suit.clubs:
        return const Color(0xFF212121); // Pure black
    }
  }

  /// Get rank string
  String get rankString {
    switch (card.rank) {
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

  /// Get suit symbol
  String get suitSymbol {
    switch (card.suit) {
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

  @override
  Widget build(BuildContext context) {
    // Debug logging to track card sizes
    debugPrint('[CARD SIZE] ${card.label}: width=$width, height=$_height');

    final backgroundColor = isPlayed
        ? const Color(0xFFE0E0E0) // Light gray for played cards
        : isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.white;

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : isPlayable
            ? const Color(0xFF757575) // Medium gray border
            : const Color(0xFFBDBDBD); // Light gray for unplayable

    final opacity = isPlayed ? 0.5 : 1.0;

    return GestureDetector(
      onTap: !isPlayed && onTap != null ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: _height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(width * 0.1), // Proportional radius
          border: Border.all(
            color: borderColor,
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: isPlayed
              ? []
              : [
                  // Outer shadow for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: width * 0.15,
                    offset: Offset(0, width * 0.06),
                  ),
                  // Inner shadow for subtle depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: width * 0.08,
                    offset: Offset(0, width * 0.02),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.1),
          child: Stack(
            children: [
              // Top-left corner index
              Positioned(
                top: width * 0.08,
                left: width * 0.12,
                child: _buildCornerIndex(opacity),
              ),
              // Bottom-right corner index (rotated 180°)
              Positioned(
                bottom: width * 0.08,
                right: width * 0.12,
                child: Transform.rotate(
                  angle: 3.14159, // 180 degrees in radians
                  child: _buildCornerIndex(opacity),
                ),
              ),
              // Center suit symbol (pronounced)
              Center(
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    suitSymbol,
                    style: TextStyle(
                      fontSize: width * 0.35,
                      color: suitColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build corner index (rank + suit stacked vertically)
  Widget _buildCornerIndex(double opacity) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank
          Text(
            rankString,
            style: TextStyle(
              fontSize: width * 0.25,
              fontWeight: FontWeight.bold,
              color: suitColor,
              height: 0.9,
            ),
          ),
          // Suit symbol
          Text(
            suitSymbol,
            style: TextStyle(
              fontSize: width * 0.22,
              color: suitColor,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Professional card back widget with pattern
class CardBackWidget extends StatelessWidget {
  final double width;
  final double? height;

  const CardBackWidget({
    super.key,
    required this.width,
    this.height,
  });

  /// Calculate height based on traditional 2.5:3.5 ratio if not provided
  double get _height => height ?? (width * 1.4);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use theme colors for card back
    final baseColor = colorScheme.primary;
    final darkColor = colorScheme.primaryContainer;

    return Container(
      width: width,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(
          color: baseColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: width * 0.15,
            offset: Offset(0, width * 0.06),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: width * 0.08,
            offset: Offset(0, width * 0.02),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.1),
        child: Container(
          decoration: BoxDecoration(
            // Gradient background using theme colors
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                darkColor,
                baseColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Diamond pattern overlay
              CustomPaint(
                painter: _CardBackPatternPainter(width: width),
                size: Size(width, _height),
              ),
              // Center icon
              Center(
                child: Icon(
                  Icons.style,
                  color: colorScheme.onPrimary.withValues(alpha: 0.4),
                  size: width * 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for card back pattern
class _CardBackPatternPainter extends CustomPainter {
  final double width;

  _CardBackPatternPainter({required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final spacing = width * 0.15;

    // Draw diagonal lines creating a diamond pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      // Top-left to bottom-right diagonals
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
      // Top-right to bottom-left diagonals
      canvas.drawLine(
        Offset(size.width - i, 0),
        Offset(size.width - i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
