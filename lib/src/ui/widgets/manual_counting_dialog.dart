import 'dart:async';

import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/logic/cribbage_scorer.dart';
import 'card_constants.dart';

/// Controller to trigger Accept from outside the dialog (e.g., ActionBar button)
class ManualCountingController extends ChangeNotifier {
  VoidCallback? _onAccept;
  int _currentScore = 0;
  bool _isShowingBreakdown = false;

  void attach(VoidCallback handler) {
    _onAccept = handler;
  }

  void detach() {
    _onAccept = null;
  }

  void triggerAccept() {
    _onAccept?.call();
  }

  void updateScore(int score) {
    if (_currentScore != score) {
      _currentScore = score;
      notifyListeners();
    }
  }

  int get currentScore => _currentScore;

  bool get isShowingBreakdown => _isShowingBreakdown;

  void setShowingBreakdown(bool value) {
    if (_isShowingBreakdown != value) {
      _isShowingBreakdown = value;
      notifyListeners();
    }
  }

  void reset() {
    if (_currentScore != 0 || _isShowingBreakdown) {
      _currentScore = 0;
      _isShowingBreakdown = false;
      notifyListeners();
    }
  }
}

/// Custom slider thumb that displays the score value inside the circle
class _ScoreThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final String text;

  const _ScoreThumbShape({
    required this.thumbRadius,
    required this.text,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the outer circle (thumb)
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, thumbRadius, borderPaint);

    // Draw the text inside the circle
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: thumbRadius * 0.7,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: textDirection,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final textCenter = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, textCenter);
  }
}

/// Manual point counting dialog with slider for user input
class ManualCountingDialog extends StatefulWidget {
  final GameState state;
  final Function(int) onScoreSubmit;
  final ManualCountingController controller;

  const ManualCountingDialog({
    super.key,
    required this.state,
    required this.onScoreSubmit,
    required this.controller,
  });

  @override
  State<ManualCountingDialog> createState() => _ManualCountingDialogState();
}

class _ManualCountingDialogState extends State<ManualCountingDialog> {
  double _sliderValue = 0;
  String? _errorMessage;
  bool _showingBreakdown = false;
  Timer? _errorTimer;

  // Valid cribbage scores (0-29 except 19, 25, 26, 27)
  // In cribbage, these scores are impossible in a hand
  static const List<int> validScores = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
    // 19 is impossible
    20, 21, 22, 23, 24,
    // 25, 26, 27 are impossible
    28, 29,
  ];

  @override
  void initState() {
    super.initState();
    // Reset slider to zero each time dialog is displayed
    _sliderValue = 0;
    widget.controller.reset();
    widget.controller.attach(_handleAccept);
  }

  @override
  void dispose() {
    widget.controller.detach();
    _errorTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ManualCountingDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset slider when counting phase changes (new hand to count)
    if (oldWidget.state.countingPhase != widget.state.countingPhase) {
      setState(() {
        _sliderValue = 0;
        _errorMessage = null;
      });
      widget.controller.reset();
      widget.controller.attach(_handleAccept);
    }
  }

  int get currentScore => validScores[_sliderValue.round()];

  DetailedScoreBreakdown? _getBreakdown() {
    final starter = widget.state.starterCard;
    if (starter == null) return null;

    final dialogData = _getDialogData();
    if (dialogData == null) return null;

    final isCrib = widget.state.countingPhase == CountingPhase.crib;
    final breakdown = CribbageScorer.scoreHandWithBreakdown(
      dialogData.hand.cast(),
      starter,
      isCrib,
    );

    return breakdown;
  }

  void _handleAccept() {
    final breakdown = _getBreakdown();
    if (breakdown == null) return;

    if (currentScore != breakdown.totalScore) {
      // Cancel any existing timer
      _errorTimer?.cancel();

      setState(() {
        _errorMessage = 'Incorrect! Please try again.';
      });

      // Start a timer to clear the error message after 3 seconds
      _errorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }

    // Score is correct, proceed
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = null;
    });
    widget.onScoreSubmit(currentScore);
    // Reset the controller for the next counting phase
    widget.controller.reset();
  }

  void _showBreakdown() {
    setState(() {
      _showingBreakdown = true;
    });
    widget.controller.setShowingBreakdown(true);
  }

  void _hideBreakdown() {
    setState(() {
      _showingBreakdown = false;
    });
    widget.controller.setShowingBreakdown(false);
  }

  @override
  Widget build(BuildContext context) {
    final dialogData = _getDialogData();
    if (dialogData == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Main dialog
        Dialog(
          insetPadding: const EdgeInsets.only(
            top: 8,
            left: 8,
            right: 8,
            bottom: 48,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Fixed header
                _buildHeader(context, dialogData.title),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        // Cards display
                        _buildCardsSection(context, dialogData.hand),
                        const SizedBox(height: 16),

                        // Slider directly under cards
                        _buildSlider(context),
                      ],
                    ),
                  ),
                ),

                // Error message (if any) - above buttons
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildErrorMessage(context),
                  ),

                // Fixed bottom buttons
                _buildBottomButtons(context),
              ],
            ),
          ),
        ),

        // Breakdown overlay (when shown)
        if (_showingBreakdown) _buildBreakdownOverlay(context),
      ],
    );
  }

  _DialogData? _getDialogData() {
    switch (widget.state.countingPhase) {
      case CountingPhase.nonDealer:
        return _DialogData(
          title: widget.state.isPlayerDealer
              ? "${widget.state.opponentName}'s Hand"
              : "${widget.state.playerName}'s Hand",
          hand: widget.state.isPlayerDealer
              ? widget.state.opponentHand
              : widget.state.playerHand,
        );

      case CountingPhase.dealer:
        return _DialogData(
          title: widget.state.isPlayerDealer
              ? "${widget.state.playerName}'s Hand"
              : "${widget.state.opponentName}'s Hand",
          hand: widget.state.isPlayerDealer
              ? widget.state.playerHand
              : widget.state.opponentHand,
        );

      case CountingPhase.crib:
        return _DialogData(
          title: widget.state.isPlayerDealer
              ? "${widget.state.playerName}'s Crib"
              : "${widget.state.opponentName}'s Crib",
          hand: widget.state.cribHand,
        );

      default:
        return null;
    }
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Spacer for symmetry
          const SizedBox(width: 40),
          // Title (centered)
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          // Help icon button
          IconButton(
            onPressed: _showBreakdown,
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Show answer',
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context, List<dynamic> hand) {
    // Sort the hand by rank (lowest to highest)
    final sortedHand = List<dynamic>.from(hand);
    sortedHand.sort((a, b) {
      final rankComparison = a.rank.index.compareTo(b.rank.index);
      if (rankComparison != 0) return rankComparison;
      return a.suit.index.compareTo(b.suit.index);
    });

    return Column(
      children: [
        Text(
          'Hand',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: CardConstants.playerHandHeight,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(sortedHand.length, (index) {
                final card = sortedHand[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                  ),
                  child: _HandCard(card: card),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Current score display (compact and prominent)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$currentScore',
                    key: ValueKey<int>(currentScore),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                  ),
                ),
                Text(
                  ' ${currentScore == 1 ? 'point' : 'points'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Score range indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '29',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Slider with custom thumb showing score inside
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: _ScoreThumbShape(
                thumbRadius: 24,
                text: '$currentScore',
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 32,
              ),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: (validScores.length - 1).toDouble(),
              divisions: validScores.length - 1,
              onChanged: (value) {
                // Cancel error timer if user is adjusting the slider
                _errorTimer?.cancel();
                setState(() {
                  _sliderValue = value;
                  // Clear error when user changes the score
                  _errorMessage = null;
                });
                // Update the controller with the new score
                widget.controller.updateScore(currentScore);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.15,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructional text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Drag the slider to select your score, then tap Accept',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Action bar hosts the accept button during manual counting
          Text(
            'Use the Accept button below to submit your score.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownOverlay(BuildContext context) {
    final breakdown = _getBreakdown();
    if (breakdown == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _hideBreakdown,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap from propagating to parent
            child: Container(
              margin: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Score Breakdown',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Breakdown content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildScoreBreakdown(context, breakdown),
                    ),
                  ),

                  // Dismiss hint
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tap anywhere to continue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(
    BuildContext context,
    DetailedScoreBreakdown breakdown,
  ) {
    if (breakdown.entries.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No points scored',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Total score display
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Score: ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              Text(
                '${breakdown.totalScore}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),

        // Breakdown table
        Card(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table header
                Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: Text(
                        'Cards',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        'Type',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        'Points',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20, thickness: 1),

                // Score entries
                ...breakdown.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 13,
                          child: Text(
                            entry.cards.map((c) => c.label).join(' '),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            entry.type,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            '${entry.points}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogData {
  final String title;
  final List<dynamic> hand;

  _DialogData({
    required this.title,
    required this.hand,
  });
}

/// Card display for manual counting dialog
class _HandCard extends StatelessWidget {
  final dynamic card;

  const _HandCard({required this.card});

  Color _getSuitColor(String label) {
    // Red for hearts (♥) and diamonds (♦), black for spades (♠) and clubs (♣)
    if (label.contains('♥') || label.contains('♦')) {
      return Colors.red.shade800;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final suitColor = _getSuitColor(card.label);

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
                color: suitColor,
              ),
        ),
      ),
    );
  }
}
