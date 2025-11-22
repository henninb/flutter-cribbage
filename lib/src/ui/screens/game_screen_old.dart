import 'package:flutter/material.dart';

import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/logic/cribbage_scorer.dart';
import '../../models/theme_models.dart';
import '../../models/game_settings.dart';
import '../widgets/theme_selector_bar.dart';
import '../widgets/cribbage_board.dart';
import '../widgets/welcome_screen.dart';
import 'settings_screen.dart';

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

        // Main game screen
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Theme selector bar at top
                ThemeSelectorBar(
                  currentTheme: widget.currentTheme,
                  onThemeSelected: widget.onThemeChange,
                  onSettingsClick: () {
                    setState(() {
                      _showSettings = true;
                    });
                  },
                ),
                // Score board (only show if game started)
                if (state.gameStarted) _ScoreBoard(state: state),
                // Main game area
                Expanded(
                  child: _GameBody(
                    state: state,
                    engine: widget.engine,
                    settings: widget.currentSettings,
                  ),
                ),
                // Cribbage board at bottom (always visible)
                CribbageBoard(
                  playerScore: state.playerScore,
                  opponentScore: state.opponentScore,
                ),
              ],
            ),
          ),
          floatingActionButton: state.gameStarted
              ? FloatingActionButton(
                  onPressed: () => widget.engine.startNewGame(),
                  tooltip: 'Start New Game',
                  child: const Icon(Icons.refresh),
                )
              : FloatingActionButton.extended(
                  onPressed: () => widget.engine.startNewGame(),
                  label: const Text('Start New Game'),
                  icon: const Icon(Icons.play_arrow),
                ),
        );
      },
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.state,
    required this.engine,
    required this.settings,
  });

  final GameState state;
  final GameEngine engine;
  final GameSettings settings;

  @override
  Widget build(BuildContext context) {
    // Show welcome screen if game hasn't started
    if (!state.gameStarted) {
      return const WelcomeScreen();
    }

    final selectable = state.currentPhase == GamePhase.cribSelection;
    final playable = state.currentPhase == GamePhase.pegging;
    final canCut = state.currentPhase == GamePhase.cutForDealer;
    final showPendingReset = state.pendingReset != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.gameStarted && canCut)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => engine.cutForDealer(),
                icon: const Icon(Icons.content_cut),
                label: const Text('Cut for Dealer'),
              ),
            ),
          if (state.currentPhase == GamePhase.dealing)
            Center(
              child: ElevatedButton(
                onPressed: () => engine.dealCards(),
                child: const Text('Deal Cards'),
              ),
            ),
          if (state.cutPlayerCard != null && state.cutOpponentCard != null)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cut For Dealer'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CardChip(title: 'You', value: state.cutPlayerCard!.label),
                        _CardChip(title: 'Opponent', value: state.cutOpponentCard!.label),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          _StatusCard(state: state),
          if (state.starterCard != null)
            _Section(
              title: 'Starter Card',
              child: _CardChip(title: 'Starter', value: state.starterCard!.label),
            ),
          _Section(
            title: 'Opponent Hand (${state.opponentHand.length - state.opponentCardsPlayed.length} remaining)',
            child: Wrap(
              spacing: 8,
              children: List.generate(
                state.opponentHand.length,
                (_) => const _CardBack(),
              ),
            ),
          ),
          if (state.peggingPile.isNotEmpty)
            _Section(
              title: 'Pegging Pile (Count: ${state.peggingCount})',
              child: Wrap(
                spacing: 6,
                children: [
                  for (final card in state.peggingPile)
                    Chip(
                      label: Text(card.label),
                    ),
                ],
              ),
            ),
          _Section(
            title: 'Your Hand',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(state.playerHand.length, (index) {
                final card = state.playerHand[index];
                final selected = state.selectedCards.contains(index);
                final played = state.playerCardsPlayed.contains(index);
                final isPlayable = playable && state.isPlayerTurn && engine.isPlayerCardPlayable(index);
                return GestureDetector(
                  onTap: () {
                    if (selectable) {
                      engine.toggleCardSelection(index);
                    } else if (isPlayable) {
                      engine.playCard(index);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: played
                          ? Colors.grey.shade400
                          : selected
                              ? Colors.teal.shade200
                              : isPlayable
                                  ? Colors.white
                                  : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Colors.teal
                            : isPlayable
                                ? Colors.black
                                : Colors.grey,
                        width: 2,
                      ),
                      boxShadow: [
                        if (!played)
                          const BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      card.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (state.cribHand.isNotEmpty)
            _Section(
              title: state.isPlayerDealer ? 'Your Crib' : 'Opponent Crib',
              child: Wrap(
                spacing: 8,
                children: state.cribHand.map((card) => Chip(label: Text(card.label))).toList(),
              ),
            ),
          const SizedBox(height: 16),
          _ActionButtons(state: state, engine: engine),
          if (state.showWinnerModal && state.winnerModalData != null)
            _WinnerBanner(data: state.winnerModalData!),
          if (state.isInHandCountingPhase)
            _CountingDialog(state: state, onContinue: engine.proceedToNextCountingPhase),
          if (showPendingReset)
            _ResetBanner(state: state, onDismissed: engine.acknowledgePendingReset),
        ],
      ),
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _scoreColumn(
              title: 'You',
              score: state.playerScore,
              subtitle: state.isPlayerDealer ? 'Dealer' : 'Pone',
            ),
            _scoreColumn(
              title: 'Opponent',
              score: state.opponentScore,
              subtitle: state.isPlayerDealer ? 'Pone' : 'Dealer',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Wins: ${state.gamesWon}'),
                Text('Losses: ${state.gamesLost}'),
                Text('Skunks: ${state.skunksFor}/${state.skunksAgainst}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreColumn({required String title, required int score, required String subtitle}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text(subtitle),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase: ${state.currentPhase.name.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(
              state.gameStatus.isEmpty ? 'Waiting for next action.' : state.gameStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        const SizedBox(height: 4),
        Chip(label: Text(value)),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state, required this.engine});

  final GameState state;
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final canConfirmCrib = state.currentPhase == GamePhase.cribSelection && state.selectedCards.length == 2;
    final canStartCounting = state.currentPhase == GamePhase.handCounting && !state.isInHandCountingPhase;
    final canGo = state.currentPhase == GamePhase.pegging && state.isPlayerTurn && !engine.playerHasLegalMove;

    final children = <Widget>[];
    if (canConfirmCrib) {
      children.add(
        ElevatedButton(
          onPressed: engine.confirmCribSelection,
          child: const Text('Confirm Crib Selection'),
        ),
      );
    }
    if (canGo) {
      children.add(
        OutlinedButton(
          onPressed: () => engine.handleGo(),
          child: const Text('Go'),
        ),
      );
    }
    if (canStartCounting) {
      children.add(
        ElevatedButton(
          onPressed: engine.startHandCounting,
          child: const Text('Start Hand Counting'),
        ),
      );
    }
    if (state.gameOver) {
      children.add(
        FilledButton.icon(
          onPressed: engine.startNewGame,
          icon: const Icon(Icons.restart_alt),
          label: const Text('New Game'),
        ),
      );
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: children,
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.data});

  final WinnerModalData data;

  @override
  Widget build(BuildContext context) {
    final color = data.playerWon ? Colors.green.shade700 : Colors.red.shade700;
    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.playerWon ? 'You won the game!' : 'Opponent won the game.',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Final score ${data.playerScore} – ${data.opponentScore}${data.wasSkunk ? ' (Skunk!)' : ''}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Record ${data.gamesWon}-${data.gamesLost}. Skunks ${data.skunksFor}/${data.skunksAgainst}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountingDialog extends StatelessWidget {
  const _CountingDialog({required this.state, required this.onContinue});

  final GameState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scores = state.handScores;
    final breakdown = switch (state.countingPhase) {
      CountingPhase.nonDealer => scores.nonDealerBreakdown,
      CountingPhase.dealer => scores.dealerBreakdown,
      CountingPhase.crib => scores.cribBreakdown,
      _ => null,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Counting ${state.countingPhase.name}'),
            if (breakdown != null)
              ...[
                const SizedBox(height: 8),
                _BreakdownList(breakdown: breakdown),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ]
            else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Score'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({required this.breakdown});

  final DetailedScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in breakdown.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.type),
                Text('+${entry.points}')
              ],
            ),
          ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total'),
            Text('+${breakdown.totalScore}')
          ],
        ),
      ],
    );
  }
}

class _ResetBanner extends StatelessWidget {
  const _ResetBanner({required this.state, required this.onDismissed});

  final GameState state;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingReset!;
    return Card(
      color: Colors.indigo.shade50,
      child: ListTile(
        title: Text(pending.message),
        subtitle: Text('Count ${pending.finalCount}, awarded ${pending.scoreAwarded} points'),
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: onDismissed,
        ),
      ),
    );
  }
}
