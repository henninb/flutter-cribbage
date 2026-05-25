import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/ui/widgets/manual_counting_dialog.dart';

void main() {
  // Zero-score hand: [4♥, 6♠, 7♣, K♦] + 3♥ starter = 0 points
  const zeroHand = [
    PlayingCard(rank: Rank.four, suit: Suit.hearts),
    PlayingCard(rank: Rank.six, suit: Suit.spades),
    PlayingCard(rank: Rank.seven, suit: Suit.clubs),
    PlayingCard(rank: Rank.king, suit: Suit.diamonds),
  ];
  const zeroStarter = PlayingCard(rank: Rank.three, suit: Suit.hearts);

  // A hand that definitely scores > 0: pair of fives + ten starter
  const scoringHand = [
    PlayingCard(rank: Rank.five, suit: Suit.hearts),
    PlayingCard(rank: Rank.five, suit: Suit.diamonds),
    PlayingCard(rank: Rank.two, suit: Suit.clubs),
    PlayingCard(rank: Rank.three, suit: Suit.spades),
  ];
  const scoringStarter = PlayingCard(rank: Rank.ten, suit: Suit.clubs);

  GameState buildState({
    CountingPhase countingPhase = CountingPhase.nonDealer,
    bool isPlayerDealer = false,
    List<PlayingCard> playerHand = zeroHand,
    List<PlayingCard> opponentHand = zeroHand,
    List<PlayingCard> cribHand = zeroHand,
    PlayingCard starter = zeroStarter,
  }) {
    return GameState(
      currentPhase: GamePhase.handCounting,
      countingPhase: countingPhase,
      isPlayerDealer: isPlayerDealer,
      playerHand: playerHand,
      opponentHand: opponentHand,
      cribHand: cribHand,
      starterCard: starter,
      playerName: 'You',
      opponentName: 'Bot',
      handScores: const HandScores(),
    );
  }

  Widget buildWidget(
    GameState state, {
    ManualCountingController? controller,
    void Function(int)? onScoreSubmit,
  }) {
    final ctrl = controller ?? ManualCountingController();
    return MaterialApp(
      home: Scaffold(
        body: ManualCountingDialog(
          state: state,
          onScoreSubmit: onScoreSubmit ?? (_) {},
          controller: ctrl,
        ),
      ),
    );
  }

  group('ManualCountingController', () {
    test('triggerAccept calls attached handler', () {
      final controller = ManualCountingController();
      var called = false;
      controller.attach(() => called = true);
      controller.triggerAccept();
      expect(called, isTrue);
    });

    test('triggerAccept is no-op after detach', () {
      final controller = ManualCountingController();
      var called = false;
      controller.attach(() => called = true);
      controller.detach();
      controller.triggerAccept();
      expect(called, isFalse);
    });

    test('triggerShowBreakdown calls attached handler', () {
      final controller = ManualCountingController();
      var called = false;
      controller.attachShowBreakdown(() => called = true);
      controller.triggerShowBreakdown();
      expect(called, isTrue);
    });

    test('triggerShowBreakdown is no-op after detachShowBreakdown', () {
      final controller = ManualCountingController();
      var called = false;
      controller.attachShowBreakdown(() => called = true);
      controller.detachShowBreakdown();
      controller.triggerShowBreakdown();
      expect(called, isFalse);
    });

    test('updateScore notifies listeners when value changes', () {
      final controller = ManualCountingController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.updateScore(7);
      expect(controller.currentScore, 7);
      expect(notified, isTrue);
    });

    test('updateScore does not notify when value is unchanged', () {
      final controller = ManualCountingController();
      controller.updateScore(7);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.updateScore(7);
      expect(notified, isFalse);
    });

    test('setShowingBreakdown updates state and notifies', () {
      final controller = ManualCountingController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setShowingBreakdown(true);
      expect(controller.isShowingBreakdown, isTrue);
      expect(notified, isTrue);
    });

    test('setShowingBreakdown does not notify when already same value', () {
      final controller = ManualCountingController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setShowingBreakdown(false);
      expect(notified, isFalse);
    });

    test('reset clears score and breakdown', () {
      final controller = ManualCountingController();
      controller.updateScore(10);
      controller.setShowingBreakdown(true);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.reset();
      expect(controller.currentScore, 0);
      expect(controller.isShowingBreakdown, isFalse);
      expect(notified, isTrue);
    });

    test('reset does not notify when already clean', () {
      final controller = ManualCountingController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.reset();
      expect(notified, isFalse);
    });
  });

  group('ManualCountingDialog', () {
    testWidgets('returns empty widget when countingPhase is none',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const GameState(
            currentPhase: GamePhase.handCounting,
            countingPhase: CountingPhase.none,
          ),
        ),
      );
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('nonDealer phase shows player name when player is not dealer',
        (tester) async {
      await tester.pumpWidget(buildWidget(buildState()));
      expect(find.textContaining("You"), findsWidgets);
    });

    testWidgets('nonDealer phase shows opponent name when player is dealer',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(buildState(isPlayerDealer: true)),
      );
      expect(find.textContaining("Bot"), findsWidgets);
    });

    testWidgets('dealer phase shows player name when player is dealer',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          buildState(
            countingPhase: CountingPhase.dealer,
            isPlayerDealer: true,
          ),
        ),
      );
      expect(find.textContaining("You"), findsWidgets);
    });

    testWidgets('dealer phase shows opponent name when player is not dealer',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          buildState(
            countingPhase: CountingPhase.dealer,
            isPlayerDealer: false,
          ),
        ),
      );
      expect(find.textContaining("Bot"), findsWidgets);
    });

    testWidgets('crib phase shows player crib label when player is dealer',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          buildState(
            countingPhase: CountingPhase.crib,
            isPlayerDealer: true,
          ),
        ),
      );
      expect(find.textContaining("Crib"), findsWidgets);
    });

    testWidgets(
        'crib phase shows opponent crib label when player is not dealer',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          buildState(
            countingPhase: CountingPhase.crib,
            isPlayerDealer: false,
          ),
        ),
      );
      expect(find.textContaining("Bot"), findsWidgets);
    });

    testWidgets('shows slider and score display', (tester) async {
      await tester.pumpWidget(buildWidget(buildState()));
      expect(find.byType(Slider), findsOneWidget);
      expect(find.textContaining('Score:'), findsOneWidget);
    });

    testWidgets('accept with correct zero score calls onScoreSubmit',
        (tester) async {
      final controller = ManualCountingController();
      int? submitted;

      await tester.pumpWidget(
        buildWidget(
          buildState(),
          controller: controller,
          onScoreSubmit: (s) => submitted = s,
        ),
      );

      // Slider starts at 0; zero-score hand scores 0 → correct
      controller.triggerAccept();
      await tester.pump();

      expect(submitted, 0);
    });

    testWidgets('accept with incorrect score shows error snackbar',
        (tester) async {
      final controller = ManualCountingController();

      await tester.pumpWidget(
        buildWidget(
          buildState(
            playerHand: scoringHand,
            opponentHand: scoringHand,
            starter: scoringStarter,
          ),
          controller: controller,
        ),
      );

      // Slider starts at 0 but hand scores > 0 → error
      controller.triggerAccept();
      await tester.pump();

      expect(find.text('Incorrect! Please try again.'), findsOneWidget);
    });

    testWidgets('triggerShowBreakdown makes breakdown overlay visible',
        (tester) async {
      final controller = ManualCountingController();

      await tester
          .pumpWidget(buildWidget(buildState(), controller: controller));

      controller.triggerShowBreakdown();
      await tester.pump();

      expect(controller.isShowingBreakdown, isTrue);
    });

    testWidgets('accept is no-op when starterCard is null', (tester) async {
      final controller = ManualCountingController();
      int? submitted;

      await tester.pumpWidget(
        buildWidget(
          GameState(
            currentPhase: GamePhase.handCounting,
            countingPhase: CountingPhase.nonDealer,
            playerHand: zeroHand,
            opponentHand: zeroHand,
            playerName: 'You',
            opponentName: 'Bot',
          ),
          controller: controller,
          onScoreSubmit: (s) => submitted = s,
        ),
      );

      controller.triggerAccept();
      await tester.pump();

      expect(submitted, isNull);
    });

    testWidgets('didUpdateWidget resets slider when counting phase changes',
        (tester) async {
      final controller = ManualCountingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualCountingDialog(
              state: buildState(countingPhase: CountingPhase.nonDealer),
              onScoreSubmit: (_) {},
              controller: controller,
            ),
          ),
        ),
      );

      // Change the counting phase
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualCountingDialog(
              state: buildState(countingPhase: CountingPhase.dealer),
              onScoreSubmit: (_) {},
              controller: controller,
            ),
          ),
        ),
      );

      expect(controller.currentScore, 0);
    });

    testWidgets('dragging slider updates displayed score', (tester) async {
      final controller = ManualCountingController();

      await tester
          .pumpWidget(buildWidget(buildState(), controller: controller));

      final slider = find.byType(Slider);
      // Drag right to increase score
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      expect(controller.currentScore, greaterThan(0));
    });

    testWidgets('breakdown overlay renders null-safe when no starter card',
        (tester) async {
      final controller = ManualCountingController();

      await tester.pumpWidget(
        buildWidget(
          GameState(
            currentPhase: GamePhase.handCounting,
            countingPhase: CountingPhase.nonDealer,
            playerHand: zeroHand,
            opponentHand: zeroHand,
            playerName: 'You',
            opponentName: 'Bot',
          ),
          controller: controller,
        ),
      );

      // Trigger breakdown with no starter — overlay shows SizedBox.shrink()
      controller.triggerShowBreakdown();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('breakdown overlay shows score content when starter is set',
        (tester) async {
      final controller = ManualCountingController();

      await tester.pumpWidget(
        buildWidget(buildState(), controller: controller),
      );

      controller.triggerShowBreakdown();
      await tester.pump();

      // The overlay should render without error and show score content
      expect(tester.takeException(), isNull);
      expect(controller.isShowingBreakdown, isTrue);
    });

    testWidgets('tapping breakdown overlay backdrop hides breakdown',
        (tester) async {
      final controller = ManualCountingController();

      await tester
          .pumpWidget(buildWidget(buildState(), controller: controller));

      controller.triggerShowBreakdown();
      await tester.pump();
      expect(controller.isShowingBreakdown, isTrue);

      // Tap the backdrop (top-left corner, outside inner dialog)
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(controller.isShowingBreakdown, isFalse);
    });
  });
}
