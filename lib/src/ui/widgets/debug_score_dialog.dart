import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/engine/game_engine.dart';

/// Debug-only dialog for manually adjusting scores
/// Activated by triple-tapping on the score display
class DebugScoreDialog extends StatefulWidget {
  final GameEngine engine;
  final int currentPlayerScore;
  final int currentOpponentScore;

  const DebugScoreDialog({
    super.key,
    required this.engine,
    required this.currentPlayerScore,
    required this.currentOpponentScore,
  });

  /// Show the debug score dialog (only in debug builds)
  static void show(
    BuildContext context,
    GameEngine engine,
    int currentPlayerScore,
    int currentOpponentScore,
  ) {
    // Only show in debug mode
    if (!kDebugMode) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DebugScoreDialog(
        engine: engine,
        currentPlayerScore: currentPlayerScore,
        currentOpponentScore: currentOpponentScore,
      ),
    );
  }

  @override
  State<DebugScoreDialog> createState() => _DebugScoreDialogState();
}

class _DebugScoreDialogState extends State<DebugScoreDialog> {
  late int _playerScore;
  late int _opponentScore;

  @override
  void initState() {
    super.initState();
    _playerScore = widget.currentPlayerScore;
    _opponentScore = widget.currentOpponentScore;
  }

  void _adjustScore(bool isPlayer, int delta) {
    setState(() {
      if (isPlayer) {
        _playerScore = (_playerScore + delta).clamp(0, 121);
      } else {
        _opponentScore = (_opponentScore + delta).clamp(0, 121);
      }
    });
  }

  void _applyScores() {
    widget.engine.updateScores(_playerScore, _opponentScore);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Debug Score Adjuster',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DEBUG MODE ONLY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Player score adjuster
          _ScoreAdjuster(
            label: widget.engine.state.playerName,
            score: _playerScore,
            onIncrement: () => _adjustScore(true, 1),
            onDecrement: () => _adjustScore(true, -1),
            onIncrementBy5: () => _adjustScore(true, 5),
            onDecrementBy5: () => _adjustScore(true, -5),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 16),

          // Opponent score adjuster
          _ScoreAdjuster(
            label: widget.engine.state.opponentName,
            score: _opponentScore,
            onIncrement: () => _adjustScore(false, 1),
            onDecrement: () => _adjustScore(false, -1),
            onIncrementBy5: () => _adjustScore(false, 5),
            onDecrementBy5: () => _adjustScore(false, -5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _applyScores,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Score adjuster widget with +/- buttons
class _ScoreAdjuster extends StatelessWidget {
  final String label;
  final int score;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrementBy5;
  final VoidCallback onDecrementBy5;

  const _ScoreAdjuster({
    required this.label,
    required this.score,
    required this.onIncrement,
    required this.onDecrement,
    required this.onIncrementBy5,
    required this.onDecrementBy5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -5 button
            IconButton(
              onPressed: score > 0 ? onDecrementBy5 : null,
              icon: const Icon(Icons.fast_rewind, size: 18),
              tooltip: '-5',
              iconSize: 18,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 2),
            // -1 button
            IconButton(
              onPressed: score > 0 ? onDecrement : null,
              icon: const Icon(Icons.remove, size: 18),
              tooltip: '-1',
              iconSize: 18,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 6),
            // Score display - Flexible to handle 3-digit scores
            Flexible(
              child: Container(
                constraints: const BoxConstraints(minWidth: 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // +1 button
            IconButton(
              onPressed: score < 121 ? onIncrement : null,
              icon: const Icon(Icons.add, size: 18),
              tooltip: '+1',
              iconSize: 18,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 2),
            // +5 button
            IconButton(
              onPressed: score < 121 ? onIncrementBy5 : null,
              icon: const Icon(Icons.fast_forward, size: 18),
              tooltip: '+5',
              iconSize: 18,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
