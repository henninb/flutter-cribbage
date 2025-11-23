import 'package:flutter/material.dart';

import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/card.dart';
import '../../models/theme_models.dart';
import '../../models/game_settings.dart';
import '../widgets/cribbage_board.dart';
import '../widgets/welcome_screen.dart';
import '../widgets/action_bar.dart';
import '../widgets/hand_counting_dialog.dart';
import '../widgets/card_constants.dart';
import '../widgets/score_animation.dart';
import 'settings_screen.dart';

/// Main game screen with zone-based layout (NO SCROLLING)
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.engine,
    required this.currentTheme,
    required this.onThemeChange,
    required this.currentSettings,
    required this.onSettingsChange,
  });

  final GameEngine engine;
  final CribbageTheme currentTheme;
  final Function(CribbageTheme) onThemeChange;
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showSettings = false;

  void _handleAdvise() {
    if (!mounted) return;

    final indices = widget.engine.getAdvice();
    if (indices.length == 2) {
      // Clear any existing selection first
      final state = widget.engine.state;
      final currentSelection = Set<int>.from(state.selectedCards);

      // Clear current selection
      for (final index in currentSelection) {
        widget.engine.toggleCardSelection(index);
      }

      // Select the advised cards
      for (final index in indices) {
        widget.engine.toggleCardSelection(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        // Show settings overlay if requested
        if (_showSettings) {
          return SettingsScreen(
            currentSettings: widget.currentSettings,
            onSettingsChange: widget.onSettingsChange,
            onBackPressed: () {
              setState(() {
                _showSettings = false;
              });
            },
          );
        }

        // Main game screen with fixed zones
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cribbage'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  setState(() {
                    _showSettings = true;
                  });
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                // Zone 1: Score Header (only when game started)
                if (state.gameStarted)
                  _ScoreHeader(
                    state: state,
                    engine: widget.engine,
                  ),

                // Zone 2: Game Area (flexible, NO SCROLL)
                Expanded(
                  child: _GameArea(
                    state: state,
                    engine: widget.engine,
                  ),
                ),

                // Zone 3: Action Bar
                ActionBar(
                  state: state,
                  onStartGame: widget.engine.startNewGame,
                  onCutForDealer: widget.engine.cutForDealer,
                  onDeal: widget.engine.dealCards,
                  onConfirmCrib: widget.engine.confirmCribSelection,
                  onGo: () => widget.engine.handleGo(),
                  onStartCounting: widget.engine.startHandCounting,
                  onAdvise: _handleAdvise,
                ),

                // Zone 4: Cribbage Board
                CribbageBoard(
                  playerScore: state.playerScore,
                  opponentScore: state.opponentScore,
                ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Score header showing scores and stats
class _ScoreHeader extends StatefulWidget {
  final GameState state;
  final GameEngine engine;

  const _ScoreHeader({
    required this.state,
    required this.engine,
  });

  @override
  State<_ScoreHeader> createState() => _ScoreHeaderState();
}

class _ScoreHeaderState extends State<_ScoreHeader> {
  @override
  Widget build(BuildContext context) {
    // Debug: Print scores being displayed
    debugPrint('[UI] ScoreHeader displaying - Player: ${widget.state.playerScore}, Opponent: ${widget.state.opponentScore}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreColumn(
            label: 'You',
            score: widget.state.playerScore,
            subtitle: widget.state.isPlayerDealer ? 'Dealer' : 'Pone',
            isDealer: widget.state.currentPhase != GamePhase.cutForDealer && widget.state.isPlayerDealer,
            scoreAnimation: widget.state.playerScoreAnimation != null
                ? ScoreAnimationWidget(
                    points: widget.state.playerScoreAnimation!.points,
                    isPlayer: widget.state.playerScoreAnimation!.isPlayer,
                    onAnimationComplete: () => widget.engine.clearScoreAnimation(true),
                  )
                : null,
          ),
          if (widget.state.starterCard != null)
            _StarterCard(card: widget.state.starterCard!),
          _ScoreColumn(
            label: 'Opponent',
            score: widget.state.opponentScore,
            subtitle: widget.state.isPlayerDealer ? 'Pone' : 'Dealer',
            isDealer: widget.state.currentPhase != GamePhase.cutForDealer && !widget.state.isPlayerDealer,
            scoreAnimation: widget.state.opponentScoreAnimation != null
                ? ScoreAnimationWidget(
                    points: widget.state.opponentScoreAnimation!.points,
                    isPlayer: widget.state.opponentScoreAnimation!.isPlayer,
                    onAnimationComplete: () => widget.engine.clearScoreAnimation(false),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int score;
  final String subtitle;
  final bool isDealer;
  final Widget? scoreAnimation;

  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.subtitle,
    required this.isDealer,
    this.scoreAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (isDealer) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'D',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (scoreAnimation != null) ...[
              const SizedBox(width: 8),
              scoreAnimation!,
            ],
          ],
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _StarterCard extends StatelessWidget {
  final dynamic card;

  const _StarterCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Starter',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            card.label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Game area - shows different content based on phase
/// NO SCROLLING - everything must fit in available space
class _GameArea extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const _GameArea({
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    // Show welcome screen if game not started
    if (!state.gameStarted) {
      return const WelcomeScreen();
    }

    // Show pending reset dialog if exists
    if (state.pendingReset != null) {
      return _PendingResetDialog(
        state: state,
        onDismiss: engine.acknowledgePendingReset,
      );
    }

    // Show winner modal if game over
    if (state.showWinnerModal && state.winnerModalData != null) {
      return _WinnerModal(
        data: state.winnerModalData!,
        onDismiss: engine.dismissWinnerModal,
      );
    }

    // Show hand counting dialog
    if (state.isInHandCountingPhase) {
      return HandCountingDialog(
        state: state,
        onContinue: engine.proceedToNextCountingPhase,
      );
    }

    // Show game content based on phase
    return _GameContent(state: state, engine: engine);
  }
}

/// Main game content - different layout per phase
class _GameContent extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const _GameContent({
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Opponent hand (only show after cards are dealt)
          if (_shouldShowOpponentHand()) _OpponentHand(state: state),

          // Middle section - varies by phase
          _buildMiddleSection(context),

          // Player hand (only show after cards are dealt)
          if (_shouldShowOpponentHand()) _PlayerHand(state: state, engine: engine),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context) {
    switch (state.currentPhase) {
      case GamePhase.cutForDealer:
        return Expanded(child: _CutCardsDisplay(state: state));

      case GamePhase.dealing:
        // Show cut cards only if we just cut for dealer (initial game start)
        if (state.showCutForDealer) {
          return Expanded(child: _CutCardsDisplay(state: state));
        }
        return const Expanded(child: SizedBox.shrink());

      case GamePhase.cribSelection:
        return Column(
          children: [
            Text(
              'Select 2 cards for the crib',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${state.selectedCards.length}/2 selected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );

      case GamePhase.pegging:
        return _PeggingDisplay(state: state);

      case GamePhase.handCounting:
        // Show pegging pile until user clicks "Count Hands"
        if (!state.isInHandCountingPhase) {
          return _PeggingDisplay(state: state);
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  bool _shouldShowOpponentHand() {
    // Only show opponent hand after cards have been dealt
    return state.currentPhase != GamePhase.cutForDealer &&
           state.currentPhase != GamePhase.dealing;
  }
}

/// Opponent hand display
class _OpponentHand extends StatelessWidget {
  final GameState state;

  const _OpponentHand({required this.state});

  @override
  Widget build(BuildContext context) {
    final cardsRemaining = state.opponentHand.length - state.opponentCardsPlayed.length;

    // Create sorted indices based on card rank (lowest to highest)
    final sortedIndices = List<int>.generate(state.opponentHand.length, (i) => i);
    sortedIndices.sort((a, b) {
      final cardA = state.opponentHand[a];
      final cardB = state.opponentHand[b];
      // First compare by rank index, then by suit for consistent ordering
      final rankComparison = cardA.rank.index.compareTo(cardB.rank.index);
      if (rankComparison != 0) return rankComparison;
      return cardA.suit.index.compareTo(cardB.suit.index);
    });

    return Column(
      children: [
        Text(
          'Opponent ($cardsRemaining cards)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: CardConstants.opponentHandHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: sortedIndices.length,
            itemBuilder: (context, displayIndex) {
              // Get the original index from the sorted list
              final originalIndex = sortedIndices[displayIndex];
              final isPlayed = state.opponentCardsPlayed.contains(originalIndex);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: isPlayed ? 0.3 : 1.0,
                  child: _CardBack(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: CardConstants.cardBackWidth,
      height: CardConstants.cardBackHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary,
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Theme.of(context).colorScheme.tertiary,
          size: 28,
        ),
      ),
    );
  }
}

/// Player hand display
class _PlayerHand extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const _PlayerHand({
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final cardsRemaining = state.playerHand.length - state.playerCardsPlayed.length;

    // Create sorted indices based on card rank (lowest to highest)
    final sortedIndices = List<int>.generate(state.playerHand.length, (i) => i);
    sortedIndices.sort((a, b) {
      final cardA = state.playerHand[a];
      final cardB = state.playerHand[b];
      // First compare by rank index, then by suit for consistent ordering
      final rankComparison = cardA.rank.index.compareTo(cardB.rank.index);
      if (rankComparison != 0) return rankComparison;
      return cardA.suit.index.compareTo(cardB.suit.index);
    });

    return Column(
      children: [
        Text(
          'You ($cardsRemaining cards)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: CardConstants.playerHandHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: sortedIndices.length,
            itemBuilder: (context, displayIndex) {
          // Get the original index from the sorted list
          final originalIndex = sortedIndices[displayIndex];
          final card = state.playerHand[originalIndex];
          final isSelected = state.selectedCards.contains(originalIndex);
          final isPlayed = state.playerCardsPlayed.contains(originalIndex);
          final isPlayable = state.currentPhase == GamePhase.pegging &&
              state.isPlayerTurn &&
              !isPlayed &&
              (state.peggingCount + card.value <= 31);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: CardConstants.cardHorizontalSpacing),
            child: _PlayingCard(
              card: card,
              isSelected: isSelected,
              isPlayed: isPlayed,
              isPlayable: isPlayable,
              onTap: () {
                if (state.currentPhase == GamePhase.cribSelection) {
                  engine.toggleCardSelection(originalIndex);
                } else if (state.currentPhase == GamePhase.pegging && state.isPlayerTurn && !isPlayed) {
                  if (isPlayable) {
                    engine.playCard(originalIndex);
                  } else {
                    // Card would exceed 31 - show feedback
                    final wouldBeCount = state.peggingCount + card.value;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot play ${card.label} - would exceed 31 (current: ${state.peggingCount}, would be: $wouldBeCount)',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange.shade700,
                      ),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
        ),
      ],
    );
  }
}

/// Playing card widget (larger, better styled)
class _PlayingCard extends StatelessWidget {
  final dynamic card;
  final bool isSelected;
  final bool isPlayed;
  final bool isPlayable;
  final VoidCallback onTap;

  const _PlayingCard({
    required this.card,
    required this.isSelected,
    required this.isPlayed,
    required this.isPlayable,
    required this.onTap,
  });

  Color _getSuitColor(String label) {
    // Red for hearts (♥) and diamonds (♦), black for spades (♠) and clubs (♣)
    if (label.contains('♥') || label.contains('♦')) {
      return Colors.red.shade800;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPlayed
        ? Colors.grey.shade400
        : isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : isPlayable
                ? Colors.white
                : Colors.grey.shade200;

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : isPlayable
            ? Theme.of(context).colorScheme.tertiary
            : Colors.grey.shade700;

    final suitColor = _getSuitColor(card.label);

    return GestureDetector(
      onTap: !isPlayed ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: CardConstants.cardWidth,
        height: CardConstants.cardHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
          border: Border.all(
            color: borderColor,
            width: isSelected ? CardConstants.selectedCardBorderWidth : CardConstants.cardBorderWidth,
          ),
          boxShadow: isPlayed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            card.label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPlayed ? Colors.grey.shade600 : suitColor,
                ),
          ),
        ),
      ),
    );
  }
}

/// Cut cards display
class _CutCardsDisplay extends StatelessWidget {
  final GameState state;

  const _CutCardsDisplay({required this.state});

  Widget _buildCutCard(BuildContext context, dynamic card) {
    final suitColor = (card.label.contains('♥') || card.label.contains('♦'))
        ? Colors.red.shade800
        : Colors.black;

    return Container(
      width: CardConstants.cardWidth,
      height: CardConstants.cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: suitColor,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!state.showCutForDealer ||
        state.cutPlayerCard == null ||
        state.cutOpponentCard == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Cut for Dealer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('You', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildCutCard(context, state.cutPlayerCard!),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('vs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Column(
                  children: [
                    const Text('Opponent', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildCutCard(context, state.cutOpponentCard!),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pegging display - count and pile with history
class _PeggingDisplay extends StatefulWidget {
  final GameState state;

  const _PeggingDisplay({required this.state});

  @override
  State<_PeggingDisplay> createState() => _PeggingDisplayState();
}

class _PeggingDisplayState extends State<_PeggingDisplay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PeggingDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to end when a card is played
    if (widget.state.peggingPile.length != oldWidget.state.peggingPile.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildCard({
    required PlayingCard card,
    required double width,
    required double height,
    required double fontSize,
    double opacity = 1.0,
  }) {
    final suitColor = (card.label.contains('♥') || card.label.contains('♦'))
        ? Colors.red.shade800
        : Colors.black;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius / 2),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(opacity),
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15 * opacity),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: suitColor.withOpacity(opacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedRounds = widget.state.peggingManager?.completedRounds ?? [];
    final hasHistory = completedRounds.isNotEmpty;
    final hasCurrentCards = widget.state.peggingPile.isNotEmpty;

    return Column(
      children: [
        // Pegging count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Count: ${widget.state.peggingCount}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        // Turn indicator
        Text(
          widget.state.isPlayerTurn ? 'Your turn' : "Opponent's turn",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: widget.state.isPlayerTurn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
        ),
        // Pegging pile with history
        if (hasHistory || hasCurrentCards) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: CardConstants.smallCardHeight + 8,
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                // Previous completed rounds (condensed and greyed)
                ...completedRounds.map((round) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cards in this round (overlapped)
                      ...List.generate(round.cards.length, (index) {
                        final card = round.cards[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 4.0 : 0.0,
                            right: index == round.cards.length - 1 ? 0.0 : 8.0,
                          ),
                          child: _buildCard(
                            card: card,
                            width: 30.0,
                            height: 42.0,
                            fontSize: 9.0,
                            opacity: 0.4,
                          ),
                        );
                      }),
                      // Round separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          width: 2,
                          height: 42.0,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  );
                }),
                // Current round (full size)
                if (hasCurrentCards)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.state.peggingPile.map((card) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildCard(
                          card: card,
                          width: CardConstants.smallCardWidth,
                          height: CardConstants.smallCardHeight,
                          fontSize: 12.0,
                          opacity: 1.0,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Pending reset dialog
class _PendingResetDialog extends StatelessWidget {
  final GameState state;
  final VoidCallback onDismiss;

  const _PendingResetDialog({
    required this.state,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingReset!;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pending.message,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Count: ${pending.finalCount}'),
              Text('Points: ${pending.scoreAwarded}'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onDismiss,
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Winner modal
class _WinnerModal extends StatelessWidget {
  final WinnerModalData data;
  final VoidCallback onDismiss;

  const _WinnerModal({
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        color: data.playerWon ? Colors.green.shade700 : Colors.red.shade700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.playerWon ? 'You Won!' : 'Opponent Won',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Final: ${data.playerScore} - ${data.opponentScore}',
                style: const TextStyle(color: Colors.white),
              ),
              if (data.wasSkunk)
                const Text(
                  'Skunk!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              Text(
                'Record: ${data.gamesWon}-${data.gamesLost}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onDismiss,
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
