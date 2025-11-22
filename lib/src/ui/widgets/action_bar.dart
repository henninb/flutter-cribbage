import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';

/// Context-sensitive action bar (Zone 3)
/// Shows different buttons based on game phase
class ActionBar extends StatelessWidget {
  final GameState state;
  final VoidCallback onStartGame;
  final VoidCallback onCutForDealer;
  final VoidCallback onDeal;
  final VoidCallback onConfirmCrib;
  final VoidCallback onGo;
  final VoidCallback onStartCounting;

  const ActionBar({
    super.key,
    required this.state,
    required this.onStartGame,
    required this.onCutForDealer,
    required this.onDeal,
    required this.onConfirmCrib,
    required this.onGo,
    required this.onStartCounting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: _buildButtons(context),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Setup phase - Start New Game
    if (!state.gameStarted) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onStartGame,
            child: const Text('Start New Game'),
          ),
        ),
      );
      return buttons;
    }

    // Cut for dealer phase
    if (state.currentPhase == GamePhase.cutForDealer) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: onCutForDealer,
            icon: const Icon(Icons.content_cut),
            label: const Text('Cut for Dealer'),
          ),
        ),
      );
      return buttons;
    }

    // Dealing phase
    if (state.currentPhase == GamePhase.dealing) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onDeal,
            child: const Text('Deal Cards'),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onStartGame,
            child: const Text('End Game'),
          ),
        ),
      );
      return buttons;
    }

    // Crib selection phase
    if (state.currentPhase == GamePhase.cribSelection) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: state.selectedCards.length == 2 ? onConfirmCrib : null,
            child: Text(state.isPlayerDealer ? 'My Crib' : "Opponent's Crib"),
          ),
        ),
      );
      return buttons;
    }

    // Pegging phase
    if (state.currentPhase == GamePhase.pegging) {
      // Show Go button if player can't play
      final canPlay = state.isPlayerTurn &&
                     state.playerHand.asMap().entries.any((entry) {
        final index = entry.key;
        final card = entry.value;
        return !state.playerCardsPlayed.contains(index) &&
               (state.peggingCount + card.value <= 31);
      });

      if (!canPlay && state.isPlayerTurn) {
        buttons.add(
          Expanded(
            child: FilledButton(
              onPressed: onGo,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Go'),
            ),
          ),
        );
      }
      return buttons;
    }

    // Hand counting phase
    if (state.currentPhase == GamePhase.handCounting && !state.isInHandCountingPhase) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onStartCounting,
            child: const Text('Count Hands'),
          ),
        ),
      );
      return buttons;
    }

    // Game over
    if (state.gameOver) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: onStartGame,
            child: const Text('New Game'),
          ),
        ),
      );
      return buttons;
    }

    return buttons;
  }
}
