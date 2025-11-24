import 'package:flutter/material.dart';

/// Simplified horizontal linear cribbage board (0-121 points)
class CribbageBoard extends StatelessWidget {
  final int playerScore;
  final int opponentScore;
  final String playerName;
  final String opponentName;

  const CribbageBoard({
    super.key,
    required this.playerScore,
    required this.opponentScore,
    required this.playerName,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Player track (bottom)
          _buildTrack(
            context,
            playerScore,
            playerName,
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 8),
          // Opponent track (top)
          _buildTrack(
            context,
            opponentScore,
            opponentName,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildTrack(
    BuildContext context,
    int score,
    String label,
    Color pegColor,
    Color trackColor,
  ) {
    return Row(
      children: [
        // Label (without score)
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Track
        Expanded(
          child: _buildBoardTrack(context, score, pegColor, trackColor),
        ),
      ],
    );
  }

  Widget _buildBoardTrack(
    BuildContext context,
    int score,
    Color pegColor,
    Color trackColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxScore = 121;
        final trackWidth = constraints.maxWidth;
        final pegPosition = (score / maxScore) * trackWidth;

        return Stack(
          children: [
            // Background track
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: trackColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress bar
            Container(
              height: 20,
              width: pegPosition.clamp(0, trackWidth),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Milestone markers (0, 30, 60, 90, 121)
            ...List.generate(5, (index) {
              final milestoneScore = [0, 30, 60, 90, 121][index];
              final position = (milestoneScore / maxScore) * trackWidth;

              return Positioned(
                left: position - 1,
                top: 0,
                child: Container(
                  width: 2,
                  height: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              );
            }),
            // Peg (circular marker at current score)
            if (score > 0)
              Positioned(
                left: pegPosition - 6,
                top: 5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: pegColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
