import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/card.dart';
import '../../models/theme_models.dart';
import '../../models/game_settings.dart';
import '../../utils/string_sanitizer.dart';
import '../widgets/cribbage_board.dart';
import '../widgets/welcome_screen.dart';
import '../widgets/action_bar.dart';
import '../widgets/hand_counting_dialog.dart';
import '../widgets/manual_counting_dialog.dart';
import '../widgets/card_constants.dart';
import '../widgets/score_animation.dart';
import '../widgets/debug_score_dialog.dart';
import 'settings_screen.dart';

/// Data passed when dragging a card
class CardDragData {
  final int cardIndex;
  final dynamic card;
  final GamePhase phase;

  const CardDragData({
    required this.cardIndex,
    required this.card,
    required this.phase,
  });
}

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
  final ManualCountingController _manualCountingController =
      ManualCountingController();

  @override
  void dispose() {
    _manualCountingController.dispose();
    super.dispose();
  }

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
        final isPlayerHandOrCrib = _isPlayerHandOrCrib(state);
        final useManualCounting =
            widget.currentSettings.countingMode == CountingMode.manual &&
                isPlayerHandOrCrib;
        final showHandCountingAccept =
            state.currentPhase == GamePhase.handCounting &&
                state.isInHandCountingPhase;
        final onCountingAccept = useManualCounting
            ? _manualCountingController.triggerAccept
            : widget.engine.proceedToNextCountingPhase;

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
                        settings: widget.currentSettings,
                        manualCountingController: _manualCountingController,
                      ),
                    ),

                    // Zone 3: Action Bar
                    ListenableBuilder(
                      listenable: _manualCountingController,
                      builder: (context, _) => ActionBar(
                        state: state,
                        onStartGame: widget.engine.startNewGame,
                        onCutForDealer: widget.engine.cutForDealer,
                        onDeal: widget.engine.dealCards,
                        onConfirmCrib: widget.engine.confirmCribSelection,
                        onGo: () => widget.engine.handleGo(),
                        onStartCounting: widget.engine.startHandCounting,
                        onCountingAccept: onCountingAccept,
                        onAdvise: _handleAdvise,
                        showHandCountingAccept: showHandCountingAccept,
                        manualCountingScore: useManualCounting
                            ? _manualCountingController.currentScore
                            : null,
                        isShowingBreakdown:
                            _manualCountingController.isShowingBreakdown,
                      ),
                    ),

                    // Zone 4: Cribbage Board
                    CribbageBoard(
                      playerScore: state.playerScore,
                      opponentScore: state.opponentScore,
                      playerName: state.playerName,
                      opponentName: state.opponentName,
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
  void _showNameDialog(BuildContext context, bool isPlayer) {
    final currentName =
        isPlayer ? widget.state.playerName : widget.state.opponentName;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${isPlayer ? "Your" : "Opponent's"} Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter name',
                border: const OutlineInputBorder(),
                helperText: 'Max ${StringSanitizer.maxNameLength} characters',
                counterText: '',
              ),
              maxLength: StringSanitizer.maxNameLength,
              inputFormatters: [
                // Allow only letters, numbers, spaces, and basic punctuation
                FilteringTextInputFormatter.allow(RegExp(r"[\w\s._\-']")),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Letters, numbers, spaces, and basic punctuation only',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final inputName = controller.text;
              final sanitizedName = StringSanitizer.sanitizeName(inputName);

              if (sanitizedName.isEmpty) {
                // Show error if name is invalid
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid name'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              // Update the name (engine will sanitize again for safety)
              widget.engine.updatePlayerName(isPlayer, sanitizedName);

              // Show feedback if name was modified during sanitization
              if (sanitizedName != inputName.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Name updated to: $sanitizedName'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print scores being displayed
    debugPrint(
        '[UI] ScoreHeader displaying - Player: ${widget.state.playerScore}, Opponent: ${widget.state.opponentScore}');

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
            label: widget.state.playerName,
            score: widget.state.playerScore,
            subtitle: widget.state.isPlayerDealer ? 'Dealer' : 'Pone',
            isDealer: widget.state.currentPhase != GamePhase.cutForDealer &&
                widget.state.isPlayerDealer,
            scoreAnimation: widget.state.playerScoreAnimation != null
                ? ScoreAnimationWidget(
                    points: widget.state.playerScoreAnimation!.points,
                    isPlayer: widget.state.playerScoreAnimation!.isPlayer,
                    onAnimationComplete: () =>
                        widget.engine.clearScoreAnimation(true),
                  )
                : null,
            onLabelTap: () => _showNameDialog(context, true),
            onSubtitleTap: () => _showNameDialog(context, true),
            engine: widget.engine,
          ),
          if (widget.state.starterCard != null)
            _StarterCard(card: widget.state.starterCard!),
          _ScoreColumn(
            label: widget.state.opponentName,
            score: widget.state.opponentScore,
            subtitle: widget.state.isPlayerDealer ? 'Pone' : 'Dealer',
            isDealer: widget.state.currentPhase != GamePhase.cutForDealer &&
                !widget.state.isPlayerDealer,
            scoreAnimation: widget.state.opponentScoreAnimation != null
                ? ScoreAnimationWidget(
                    points: widget.state.opponentScoreAnimation!.points,
                    isPlayer: widget.state.opponentScoreAnimation!.isPlayer,
                    onAnimationComplete: () =>
                        widget.engine.clearScoreAnimation(false),
                  )
                : null,
            onLabelTap: () => _showNameDialog(context, false),
            onSubtitleTap: () => _showNameDialog(context, false),
            engine: widget.engine,
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatefulWidget {
  final String label;
  final int score;
  final String subtitle;
  final bool isDealer;
  final Widget? scoreAnimation;
  final VoidCallback? onLabelTap;
  final VoidCallback? onSubtitleTap;
  final GameEngine engine;

  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.subtitle,
    required this.isDealer,
    this.scoreAnimation,
    this.onLabelTap,
    this.onSubtitleTap,
    required this.engine,
  });

  @override
  State<_ScoreColumn> createState() => _ScoreColumnState();
}

class _ScoreColumnState extends State<_ScoreColumn> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleScoreTap() {
    // Only enable in debug mode
    if (!kDebugMode) return;

    final now = DateTime.now();

    // Reset tap count if more than 500ms has passed since last tap
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 500)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Show debug dialog on triple tap
    if (_tapCount >= 3) {
      _tapCount = 0;
      _lastTapTime = null;

      DebugScoreDialog.show(
        context,
        widget.engine,
        widget.engine.state.playerScore,
        widget.engine.state.opponentScore,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: widget.onLabelTap,
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      decoration: widget.onLabelTap != null
                          ? TextDecoration.underline
                          : null,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
              ),
            ),
            if (widget.isDealer) ...[
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
        GestureDetector(
          onTap: _handleScoreTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.score}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.scoreAnimation != null) ...[
                const SizedBox(width: 8),
                widget.scoreAnimation!,
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: widget.onSubtitleTap,
          child: Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  decoration: widget.onSubtitleTap != null
                      ? TextDecoration.underline
                      : null,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
          ),
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

/// Helper function to determine if the current counting phase is for the player's hand/crib
bool _isPlayerHandOrCrib(GameState state) {
  switch (state.countingPhase) {
    case CountingPhase.nonDealer:
      // Non-dealer hand: player's hand if player is NOT dealer
      return !state.isPlayerDealer;
    case CountingPhase.dealer:
      // Dealer hand: player's hand if player IS dealer
      return state.isPlayerDealer;
    case CountingPhase.crib:
      // Crib: player's crib if player IS dealer (crib always belongs to dealer)
      return state.isPlayerDealer;
    default:
      return false;
  }
}

/// Game area - shows different content based on phase
/// NO SCROLLING - everything must fit in available space
class _GameArea extends StatelessWidget {
  final GameState state;
  final GameEngine engine;
  final GameSettings settings;
  final ManualCountingController manualCountingController;

  const _GameArea({
    required this.state,
    required this.engine,
    required this.settings,
    required this.manualCountingController,
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

    // Show hand counting dialog (manual or automatic based on settings)
    if (state.isInHandCountingPhase) {
      // Determine if this is the player's hand/crib
      final isPlayerHandOrCrib = _isPlayerHandOrCrib(state);

      // Use manual counting only for player's hands/crib (not opponent's)
      final useManualCounting =
          settings.countingMode == CountingMode.manual && isPlayerHandOrCrib;

      if (useManualCounting) {
        return ManualCountingDialog(
          state: state,
          onScoreSubmit: engine.proceedToNextCountingPhaseWithManualScore,
          controller: manualCountingController,
        );
      } else {
        return HandCountingDialog(
          state: state,
        );
      }
    }

    // Show game content based on phase
    return _GameContent(state: state, engine: engine, settings: settings);
  }
}

/// Main game content - different layout per phase
class _GameContent extends StatelessWidget {
  final GameState state;
  final GameEngine engine;
  final GameSettings settings;

  const _GameContent({
    required this.state,
    required this.engine,
    required this.settings,
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
          if (_shouldShowOpponentHand())
            _PlayerHand(state: state, engine: engine, settings: settings),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context) {
    switch (state.currentPhase) {
      case GamePhase.cutForDealer:
        // Show spread deck (handles both pre-selection and post-selection states)
        if (state.cutDeck.isNotEmpty) {
          return Expanded(
            child: _SpreadDeck(
              state: state,
              engine: engine,
            ),
          );
        }
        return const Expanded(child: SizedBox.shrink());

      case GamePhase.dealing:
        // Show spread deck with cut cards if we just cut for dealer
        if (state.showCutForDealer && state.playerHasSelectedCutCard) {
          return Expanded(
            child: _SpreadDeck(
              state: state,
              engine: engine,
            ),
          );
        }
        return const Expanded(child: SizedBox.shrink());

      case GamePhase.cribSelection:
        // Show drop zone for drag mode, otherwise show instructions
        if (settings.cardSelectionMode == CardSelectionMode.drag) {
          return _CribDropZone(
            state: state,
            engine: engine,
            settings: settings,
          );
        }
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
        return _PeggingDisplay(
          state: state,
          engine: engine,
          settings: settings,
        );

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
    final cardsRemaining =
        state.opponentHand.length - state.opponentCardsPlayed.length;

    // Create sorted indices based on card rank (lowest to highest)
    final sortedIndices =
        List<int>.generate(state.opponentHand.length, (i) => i);
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
          '${state.opponentName} ($cardsRemaining cards)',
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
              final isPlayed =
                  state.opponentCardsPlayed.contains(originalIndex);
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
            color: Colors.black.withValues(alpha: 0.3),
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
  final GameSettings settings;

  const _PlayerHand({
    required this.state,
    required this.engine,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final cardsRemaining =
        state.playerHand.length - state.playerCardsPlayed.length;

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
          '${state.playerName} ($cardsRemaining cards)',
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

              // Wrap card in draggable if drag mode is enabled
              Widget cardWidget = _PlayingCard(
                card: card,
                isSelected: isSelected,
                isPlayed: isPlayed,
                isPlayable: isPlayable,
                isDragMode:
                    settings.cardSelectionMode == CardSelectionMode.drag,
                onTap: settings.cardSelectionMode == CardSelectionMode.drag
                    ? null
                    : () {
                        if (state.currentPhase == GamePhase.cribSelection) {
                          engine.toggleCardSelection(originalIndex);
                        } else if (state.currentPhase == GamePhase.pegging &&
                            state.isPlayerTurn &&
                            !isPlayed) {
                          if (isPlayable) {
                            engine.playCard(originalIndex);
                          } else {
                            // Card would exceed 31 - show feedback
                            final wouldBeCount =
                                state.peggingCount + card.value;
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
              );

              // Wrap in Draggable for drag mode
              if (settings.cardSelectionMode == CardSelectionMode.drag &&
                  !isPlayed) {
                final dragData = CardDragData(
                  cardIndex: originalIndex,
                  card: card,
                  phase: state.currentPhase,
                );

                cardWidget = Draggable<CardDragData>(
                  data: dragData,
                  feedback: Transform.scale(
                    scale: 1.2,
                    child: Opacity(
                      opacity: 0.7,
                      child: _PlayingCard(
                        card: card,
                        isSelected: false,
                        isPlayed: false,
                        isPlayable: isPlayable,
                        isDragMode: true,
                        onTap: null,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _PlayingCard(
                      card: card,
                      isSelected: isSelected,
                      isPlayed: isPlayed,
                      isPlayable: isPlayable,
                      isDragMode: true,
                      onTap: null,
                    ),
                  ),
                  child: cardWidget,
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: CardConstants.cardHorizontalSpacing),
                child: cardWidget,
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
  final bool isDragMode;
  final VoidCallback? onTap;

  const _PlayingCard({
    required this.card,
    required this.isSelected,
    required this.isPlayed,
    required this.isPlayable,
    required this.isDragMode,
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
      onTap: !isPlayed && onTap != null ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: CardConstants.cardWidth,
        height: CardConstants.cardHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
          border: Border.all(
            color: borderColor,
            width: isSelected
                ? CardConstants.selectedCardBorderWidth
                : CardConstants.cardBorderWidth,
          ),
          boxShadow: isPlayed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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

/// Spread deck display for interactive cut selection
class _SpreadDeck extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const _SpreadDeck({
    required this.state,
    required this.engine,
  });

  Widget _buildCutCard(BuildContext context, PlayingCard card,
      {required double width, required double height}) {
    final suitColor = (card.label.contains('♥') || card.label.contains('♦'))
        ? Colors.red.shade800
        : Colors.black;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final deckSize = state.cutDeck.length;

    if (deckSize == 0) {
      return const SizedBox.shrink();
    }

    // Calculate card width and overlap
    const cardWidth = 60.0;
    const cardHeight = 90.0;
    const cutCardWidth = 80.0;
    const cutCardHeight = 120.0;

    // Calculate spacing between cards to fit on screen with padding
    final availableWidth = screenWidth - 32; // 16px padding on each side
    final spacing =
        (availableWidth - cardWidth) / (deckSize - 1).clamp(1, double.infinity);
    final finalSpacing =
        spacing.clamp(0.0, cardWidth * 0.8).toDouble(); // Max 80% overlap

    // Calculate total width needed for the spread
    final totalWidth = ((deckSize - 1) * finalSpacing + cardWidth).toDouble();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            state.playerHasSelectedCutCard
                ? 'Cut for Dealer'
                : 'Tap the deck to cut for dealer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: cardHeight,
            width: totalWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(
                deckSize,
                (index) {
                  return Positioned(
                    left: index * finalSpacing,
                    child: GestureDetector(
                      onTap: state.playerHasSelectedCutCard
                          ? null
                          : () => engine.selectCutCard(index),
                      child: _CardBackWidget(
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Show cut cards if player has selected
          if (state.playerHasSelectedCutCard &&
              state.cutPlayerCard != null &&
              state.cutOpponentCard != null) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player's cut card
                Column(
                  children: [
                    _buildCutCard(
                      context,
                      state.cutPlayerCard!,
                      width: cutCardWidth,
                      height: cutCardHeight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.playerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Show dealer badge if player is dealer (and not a tie)
                    if (state.isPlayerDealer &&
                        state.cutPlayerCard!.rank.index !=
                            state.cutOpponentCard!.rank.index) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'DEALER',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                // VS indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'vs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // Opponent's cut card
                Column(
                  children: [
                    _buildCutCard(
                      context,
                      state.cutOpponentCard!,
                      width: cutCardWidth,
                      height: cutCardHeight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.opponentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Show dealer badge if opponent is dealer (and not a tie)
                    if (!state.isPlayerDealer &&
                        state.cutPlayerCard!.rank.index !=
                            state.cutOpponentCard!.rank.index) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'DEALER',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Show tie message if cards are equal
            if (state.cutPlayerCard!.rank.index ==
                state.cutOpponentCard!.rank.index) ...[
              const SizedBox(height: 16),
              Text(
                'Tie! Cut again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const _CardBackWidget({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary,
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Theme.of(context).colorScheme.tertiary,
          size: 24,
        ),
      ),
    );
  }
}

/// Pegging display - count and pile with history
class _PeggingDisplay extends StatefulWidget {
  final GameState state;
  final GameEngine? engine;
  final GameSettings? settings;

  const _PeggingDisplay({
    required this.state,
    this.engine,
    this.settings,
  });

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

  /// Calculate the total width needed for fanned/overlapped cards
  /// Formula: (numCards - 1) × overlap + fullCardWidth
  double _calculateFannedWidth(int numCards) {
    if (numCards == 0) return 0;
    if (numCards == 1) return CardConstants.activePeggingCardWidth;
    return ((numCards - 1) * CardConstants.peggingCardOverlap) +
        CardConstants.activePeggingCardWidth;
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
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(CardConstants.cardBorderRadius / 2),
        border: Border.all(
          color: Colors.grey.shade700.withValues(alpha: opacity),
          width: CardConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15 * opacity),
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
            color: suitColor.withValues(alpha: opacity),
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
          widget.state.isPlayerTurn
              ? "${StringSanitizer.possessive(widget.state.playerName)} turn"
              : "${StringSanitizer.possessive(widget.state.opponentName)} turn",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: widget.state.isPlayerTurn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
        ),
        // Pegging pile with history (wrapped in drop zone for drag mode)
        const SizedBox(height: 8),
        _buildPileArea(context, completedRounds, hasHistory, hasCurrentCards),
      ],
    );
  }

  Widget _buildPileArea(BuildContext context, List<dynamic> completedRounds,
      bool hasHistory, bool hasCurrentCards) {
    // Check if drag mode is enabled
    final isDragMode =
        widget.settings?.cardSelectionMode == CardSelectionMode.drag;
    final engine = widget.engine;
    final showDropZone =
        isDragMode && engine != null && widget.state.isPlayerTurn;

    return SizedBox(
      height: CardConstants.activePeggingCardHeight + 8,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          // Previous completed rounds (fanned and greyed)
          ...completedRounds.map((round) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cards in this round (fanned/overlapped)
                SizedBox(
                  width: _calculateFannedWidth(round.cards.length),
                  height: CardConstants.activePeggingCardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(
                      round.cards.length,
                      (index) {
                        final card = round.cards[index];
                        return Positioned(
                          left: index * CardConstants.peggingCardOverlap,
                          child: _buildCard(
                            card: card,
                            width: CardConstants.activePeggingCardWidth,
                            height: CardConstants.activePeggingCardHeight,
                            fontSize: 14.0,
                            opacity: 1.0,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Round separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 2,
                    height: CardConstants.activePeggingCardHeight,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            );
          }),
          // Current round (full size, fanned/overlapped)
          if (hasCurrentCards)
            SizedBox(
              width: _calculateFannedWidth(widget.state.peggingPile.length),
              height: CardConstants.activePeggingCardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(
                  widget.state.peggingPile.length,
                  (index) {
                    final card = widget.state.peggingPile[index];
                    return Positioned(
                      left: index * CardConstants.peggingCardOverlap,
                      child: _buildCard(
                        card: card,
                        width: CardConstants.activePeggingCardWidth,
                        height: CardConstants.activePeggingCardHeight,
                        fontSize: 14.0,
                        opacity: 1.0,
                      ),
                    );
                  },
                ),
              ),
            ),
          // Drop zone appears after all cards (at the position of next card)
          if (showDropZone)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _PeggingPileDropZone(
                state: widget.state,
                engine: engine,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorScheme.scrim.withOpacity(0.35),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.toll_outlined,
                      size: 28,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pile reset',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pending.message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pile',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.75),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pending.pile
                            .map(
                              (card) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.shadow.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  card.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Count',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.85),
                                ),
                          ),
                          Text(
                            '${pending.finalCount}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Points',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.85),
                                ),
                          ),
                          Text(
                            '${pending.scoreAwarded}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap anywhere to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Winner modal
class _WinnerModal extends StatefulWidget {
  final WinnerModalData data;
  final VoidCallback onDismiss;

  const _WinnerModal({
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_WinnerModal> createState() => _WinnerModalState();
}

class _WinnerModalState extends State<_WinnerModal> {
  @override
  Widget build(BuildContext context) {
    // Get engine from context to access current state
    final engine =
        context.findAncestorStateOfType<_GameScreenState>()?.widget.engine;
    final playerName = engine?.state.playerName ?? 'You';
    final opponentName = engine?.state.opponentName ?? 'Opponent';

    final winnerName = widget.data.playerWon ? playerName : opponentName;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.data.playerWon
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                          widget.data.playerWon
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy/Crown Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.data.playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.data.playerWon
                                  ? Icons.emoji_events
                                  : Icons.close,
                              size: 40,
                              color: widget.data.playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Winner Name
                          Text(
                            '$winnerName Won!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: widget.data.playerWon
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Skunk Badge
                          if (widget.data.wasDoubleSkunk)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade600,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.whatshot,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'DOUBLE SKUNK!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          else if (widget.data.wasSkunk)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SKUNK!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Final Score
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.data.playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Final Score',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: widget.data.playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.data.playerScore} - ${widget.data.opponentScore}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: widget.data.playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Statistics Grid
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.data.playerWon
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Statistics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: widget.data.playerWon
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _StatRow(
                                  label: 'Record',
                                  value:
                                      '${widget.data.gamesWon} - ${widget.data.gamesLost}',
                                  icon: Icons.sports_score,
                                  isPlayerWin: widget.data.playerWon,
                                ),
                                const SizedBox(height: 6),
                                _StatRow(
                                  label: 'Skunks',
                                  value:
                                      '${widget.data.skunksFor} - ${widget.data.skunksAgainst}',
                                  icon: Icons.local_fire_department,
                                  isPlayerWin: widget.data.playerWon,
                                ),
                                const SizedBox(height: 6),
                                _StatRow(
                                  label: 'Double Skunks',
                                  value:
                                      '${widget.data.doubleSkunksFor} - ${widget.data.doubleSkunksAgainst}',
                                  icon: Icons.whatshot,
                                  isPlayerWin: widget.data.playerWon,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat row widget for statistics display
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPlayerWin;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isPlayerWin,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isPlayerWin
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;

    return Row(
      children: [
        Icon(
          icon,
          color: textColor.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Crib selection drop zone
class _CribDropZone extends StatefulWidget {
  final GameState state;
  final GameEngine engine;
  final GameSettings settings;

  const _CribDropZone({
    required this.state,
    required this.engine,
    required this.settings,
  });

  @override
  State<_CribDropZone> createState() => _CribDropZoneState();
}

class _CribDropZoneState extends State<_CribDropZone> {
  bool _isHovering = false;

  void _undoSelection() {
    // Clear all selected cards
    final selectedIndices = List<int>.from(widget.state.selectedCards);
    for (final index in selectedIndices) {
      widget.engine.toggleCardSelection(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.state.selectedCards.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Drop zone
        DragTarget<CardDragData>(
          onWillAcceptWithDetails: (details) {
            // Only accept cards during crib selection phase
            return details.data.phase == GamePhase.cribSelection &&
                widget.state.selectedCards.length < 2;
          },
          onAcceptWithDetails: (details) {
            // Add card to crib selection
            widget.engine.toggleCardSelection(details.data.cardIndex);
            setState(() {
              _isHovering = false;
            });
          },
          onMove: (details) {
            if (!_isHovering) {
              setState(() {
                _isHovering = true;
              });
            }
          },
          onLeave: (details) {
            setState(() {
              _isHovering = false;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isHovering
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                border: Border.all(
                  color: _isHovering
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: _isHovering ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isHovering
                        ? 'Drop card here for crib'
                        : 'Drag 2 cards here for the crib',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _isHovering
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight:
                              _isHovering ? FontWeight.bold : FontWeight.normal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.state.selectedCards.length}/2 selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
        // Undo button (only visible when cards are selected)
        if (hasSelection) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: _undoSelection,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo selection',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ],
    );
  }
}

/// Card silhouette drop zone for pegging - shows where next card will be placed
class _PeggingPileDropZone extends StatefulWidget {
  final GameState state;
  final GameEngine engine;

  const _PeggingPileDropZone({
    required this.state,
    required this.engine,
  });

  @override
  State<_PeggingPileDropZone> createState() => _PeggingPileDropZoneState();
}

class _PeggingPileDropZoneState extends State<_PeggingPileDropZone> {
  bool _isHovering = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardDragData>(
      onWillAcceptWithDetails: (details) {
        // Only accept cards during pegging phase
        if (details.data.phase != GamePhase.pegging ||
            !widget.state.isPlayerTurn) {
          return false;
        }

        final card = details.data.card;
        final wouldExceed = widget.state.peggingCount + card.value > 31;

        if (wouldExceed) {
          setState(() {
            _errorMessage = 'Cannot play ${card.label} - would exceed 31';
          });
          return false;
        }

        setState(() {
          _errorMessage = null;
        });
        return true;
      },
      onAcceptWithDetails: (details) {
        // Play the card
        widget.engine.playCard(details.data.cardIndex);
        setState(() {
          _isHovering = false;
          _errorMessage = null;
        });
      },
      onMove: (details) {
        if (!_isHovering) {
          setState(() {
            _isHovering = true;
          });
        }
      },
      onLeave: (details) {
        setState(() {
          _isHovering = false;
          _errorMessage = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final hasError = _errorMessage != null;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: CardConstants.activePeggingCardWidth,
              height: CardConstants.activePeggingCardHeight,
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red.shade100.withValues(alpha: 0.2)
                    : _isHovering
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3)
                        : Colors.transparent,
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade700
                      : _isHovering
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.5),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius:
                    BorderRadius.circular(CardConstants.cardBorderRadius / 2),
              ),
              child: Center(
                child: hasError
                    ? Icon(
                        Icons.close,
                        color: Colors.red.shade700,
                        size: 24,
                      )
                    : Icon(
                        _isHovering ? Icons.add : Icons.more_horiz,
                        color: _isHovering
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.5),
                        size: 24,
                      ),
              ),
            ),
            if (_isHovering || hasError)
              Positioned(
                top: -16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasError
                        ? Colors.red.shade50
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hasError ? _errorMessage! : 'Drop here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasError
                              ? Colors.red.shade700
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
