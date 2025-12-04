import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../utils/string_sanitizer.dart';

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
  final VoidCallback onCountingAccept;
  final VoidCallback onAdvise;
  final VoidCallback? onShowBreakdown;
  final bool showHandCountingAccept;
  final int? manualCountingScore;
  final bool isShowingBreakdown;

  const ActionBar({
    super.key,
    required this.state,
    required this.onStartGame,
    required this.onCutForDealer,
    required this.onDeal,
    required this.onConfirmCrib,
    required this.onGo,
    required this.onStartCounting,
    required this.onCountingAccept,
    required this.onAdvise,
    this.onShowBreakdown,
    this.showHandCountingAccept = false,
    this.manualCountingScore,
    this.isShowingBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = _buildButtons(context);
    final isEmpty = buttons.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: isEmpty
              ? BorderSide.none
              : BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
          bottom: isEmpty
              ? BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: buttons,
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Disable all buttons when pending reset modal is showing
    if (state.pendingReset != null) {
      return buttons;
    }

    // Disable all buttons when manual counting breakdown is showing
    if (isShowingBreakdown) {
      return buttons;
    }

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

    // Cut for dealer phase - no button needed, deck is shown automatically
    // Only show a button if there's a tie and user needs to cut again
    if (state.currentPhase == GamePhase.cutForDealer) {
      // If player has already selected and it's a tie, show "Cut Again" button
      if (state.playerHasSelectedCutCard &&
          state.cutPlayerCard != null &&
          state.cutOpponentCard != null &&
          state.cutPlayerCard!.rank.index ==
              state.cutOpponentCard!.rank.index) {
        buttons.add(
          Expanded(
            child: FilledButton.icon(
              onPressed: onCutForDealer,
              icon: const Icon(Icons.refresh),
              label: const Text('Cut Again'),
            ),
          ),
        );
      }
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
      return buttons;
    }

    // Crib selection phase
    if (state.currentPhase == GamePhase.cribSelection) {
      // Show Advise button when less than 2 cards selected
      // Show Crib button when exactly 2 cards selected
      if (state.selectedCards.length < 2) {
        buttons.add(
          Expanded(
            child: FilledButton(
              onPressed: onAdvise,
              child: const Text('Advise'),
            ),
          ),
        );
      } else {
        buttons.add(
          Expanded(
            child: FilledButton(
              onPressed: onConfirmCrib,
              child: Text(
                state.isPlayerDealer
                    ? "${StringSanitizer.possessive(state.playerName)} Crib"
                    : "${StringSanitizer.possessive(state.opponentName)} Crib",
              ),
            ),
          ),
        );
      }
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
    if (state.currentPhase == GamePhase.handCounting &&
        !state.isInHandCountingPhase) {
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

    // Hand counting active - show accept in the action bar
    if (state.currentPhase == GamePhase.handCounting &&
        state.isInHandCountingPhase &&
        showHandCountingAccept) {
      // Use manual counting score if provided, otherwise use state scores
      final points = manualCountingScore ?? _currentCountingPoints();
      final label = points != null
          ? 'Accept ($points ${points == 1 ? "point" : "points"})'
          : 'Accept (0)';

      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: onCountingAccept,
            icon: const Icon(Icons.check_circle, size: 22),
            label: Text(label),
          ),
        ),
      );

      // Add light bulb button for manual counting mode
      if (onShowBreakdown != null) {
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          IconButton(
            onPressed: onShowBreakdown,
            icon: Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Show answer',
            iconSize: 28,
          ),
        );
      }

      return buttons;
    }

    // Game over
    if (state.gameOver) {
      buttons.add(
        Expanded(
          child: FilledButton(
            onPressed: state.showWinnerModal ? null : onStartGame,
            child: const Text('New Game'),
          ),
        ),
      );
      return buttons;
    }

    return buttons;
  }

  int? _currentCountingPoints() {
    switch (state.countingPhase) {
      case CountingPhase.nonDealer:
        return state.handScores.nonDealerScore;
      case CountingPhase.dealer:
        return state.handScores.dealerScore;
      case CountingPhase.crib:
        return state.handScores.cribScore;
      default:
        return null;
    }
  }
}
