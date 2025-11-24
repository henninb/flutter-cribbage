import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/logic/cribbage_scorer.dart';
import 'card_constants.dart';

/// Full-screen hand counting dialog matching Android app
class HandCountingDialog extends StatelessWidget {
  final GameState state;
  final VoidCallback onContinue;

  const HandCountingDialog({
    super.key,
    required this.state,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which hand and breakdown to show
    final dialogData = _getDialogData();
    if (dialogData == null) return const SizedBox.shrink();

    return Dialog(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Cards display
                    _buildCardsSection(context, dialogData.hand),
                    const SizedBox(height: 16),

                    // Score breakdown table
                    _buildScoreBreakdown(context, dialogData.breakdown),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            _buildAcceptButton(context, dialogData.breakdown),
          ],
        ),
      ),
    );
  }

  _DialogData? _getDialogData() {
    final scores = state.handScores;

    debugPrint('[DIALOG DEBUG] ===== _getDialogData called =====');
    debugPrint('[DIALOG DEBUG] CountingPhase: ${state.countingPhase}');
    debugPrint('[DIALOG DEBUG] isInHandCountingPhase: ${state.isInHandCountingPhase}');
    debugPrint('[DIALOG DEBUG] gameOver: ${state.gameOver}');
    debugPrint('[DIALOG DEBUG] showWinnerModal: ${state.showWinnerModal}');
    debugPrint('[DIALOG DEBUG] NonDealer breakdown: ${scores.nonDealerBreakdown?.entries.length} entries');
    debugPrint('[DIALOG DEBUG] Dealer breakdown: ${scores.dealerBreakdown?.entries.length} entries');
    debugPrint('[DIALOG DEBUG] Crib breakdown: ${scores.cribBreakdown?.entries.length} entries');

    switch (state.countingPhase) {
      case CountingPhase.nonDealer:
        debugPrint('[DIALOG DEBUG] Showing nonDealer - breakdown is ${scores.nonDealerBreakdown == null ? "null" : "not null with ${scores.nonDealerBreakdown!.entries.length} entries"}');
        return _DialogData(
          title: state.isPlayerDealer ? "${state.opponentName}'s Hand" : "${state.playerName}'s Hand",
          hand: state.isPlayerDealer ? state.opponentHand : state.playerHand,
          breakdown: scores.nonDealerBreakdown,
        );

      case CountingPhase.dealer:
        debugPrint('[DIALOG DEBUG] Showing dealer - breakdown is ${scores.dealerBreakdown == null ? "null" : "not null with ${scores.dealerBreakdown!.entries.length} entries"}');
        return _DialogData(
          title: state.isPlayerDealer ? "${state.playerName}'s Hand" : "${state.opponentName}'s Hand",
          hand: state.isPlayerDealer ? state.playerHand : state.opponentHand,
          breakdown: scores.dealerBreakdown,
        );

      case CountingPhase.crib:
        debugPrint('[DIALOG DEBUG] Showing crib - breakdown is ${scores.cribBreakdown == null ? "null" : "not null with ${scores.cribBreakdown!.entries.length} entries"}');
        return _DialogData(
          title: state.isPlayerDealer ? "${state.playerName}'s Crib" : "${state.opponentName}'s Crib",
          hand: state.cribHand,
          breakdown: scores.cribBreakdown,
        );

      default:
        debugPrint('[DIALOG DEBUG] Counting phase is ${state.countingPhase} - returning null');
        return null;
    }
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context, List<dynamic> hand) {
    // Sort the hand by rank (lowest to highest)
    final sortedHand = List<dynamic>.from(hand);
    sortedHand.sort((a, b) {
      // First compare by rank index, then by suit for consistent ordering
      final rankComparison = a.rank.index.compareTo(b.rank.index);
      if (rankComparison != 0) return rankComparison;
      return a.suit.index.compareTo(b.suit.index);
    });

    return Column(
      children: [
        // Hand cards
        Column(
          children: [
            Text(
              'Hand',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
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
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown(
    BuildContext context,
    DetailedScoreBreakdown? breakdown,
  ) {
    if (breakdown == null || breakdown.entries.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceVariant,
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

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
            ...breakdown.entries.map((entry) => Padding(
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
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, DetailedScoreBreakdown? breakdown) {
    final points = breakdown?.totalScore ?? 0;
    final pointsText = points == 1 ? 'point' : 'points';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.check_circle, size: 24),
          label: Text(
            'Accept ($points $pointsText)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogData {
  final String title;
  final List<dynamic> hand;
  final DetailedScoreBreakdown? breakdown;

  _DialogData({
    required this.title,
    required this.hand,
    this.breakdown,
  });
}

/// Card display for hand counting dialog
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
}
