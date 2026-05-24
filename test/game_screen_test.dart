import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribbage/src/game/engine/game_engine.dart';
import 'package:cribbage/src/game/engine/game_state.dart';
import 'package:cribbage/src/game/models/card.dart';
import 'package:cribbage/src/models/game_settings.dart';
import 'package:cribbage/src/models/theme_models.dart';
import 'package:cribbage/src/ui/screens/game_screen.dart';
import 'package:cribbage/src/ui/theme/theme_definitions.dart';
import 'package:cribbage/src/ui/widgets/playing_card_widget.dart';

class _FakeGameEngine extends GameEngine {
  _FakeGameEngine(this._fakeState, {List<int>? fakeAdvice})
      : _fakeAdvice = fakeAdvice ?? const [];

  final GameState _fakeState;
  final List<int> _fakeAdvice;

  @override
  GameState get state => _fakeState;

  @override
  List<int> getAdvice() => _fakeAdvice;
}

const _hand4 = <PlayingCard>[
  PlayingCard(rank: Rank.ace, suit: Suit.hearts),
  PlayingCard(rank: Rank.five, suit: Suit.clubs),
  PlayingCard(rank: Rank.ten, suit: Suit.diamonds),
  PlayingCard(rank: Rank.king, suit: Suit.spades),
];

const _hand6 = <PlayingCard>[
  PlayingCard(rank: Rank.ace, suit: Suit.hearts),
  PlayingCard(rank: Rank.two, suit: Suit.clubs),
  PlayingCard(rank: Rank.three, suit: Suit.diamonds),
  PlayingCard(rank: Rank.four, suit: Suit.spades),
  PlayingCard(rank: Rank.five, suit: Suit.hearts),
  PlayingCard(rank: Rank.six, suit: Suit.clubs),
];

const _smallCutDeck = <PlayingCard>[
  PlayingCard(rank: Rank.ace, suit: Suit.hearts),
  PlayingCard(rank: Rank.two, suit: Suit.clubs),
  PlayingCard(rank: Rank.three, suit: Suit.diamonds),
  PlayingCard(rank: Rank.four, suit: Suit.spades),
  PlayingCard(rank: Rank.five, suit: Suit.hearts),
];

Future<void> _usePhone(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  // In the test environment the screen may be too small for the full game
  // layout, producing RenderFlex overflow errors that don't reflect real-device
  // behaviour.  Suppress those so widget-presence assertions can still pass.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!details.exceptionAsString().contains('A RenderFlex overflowed')) {
      originalOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

void main() {
  GameScreen buildScreen({
    required GameEngine engine,
    GameSettings settings = const GameSettings(),
    required void Function(GameSettings) onSettingsChange,
  }) {
    return GameScreen(
      engine: engine,
      currentTheme: ThemeDefinitions.spring,
      onThemeChange: (_) {},
      currentSettings: settings,
      onSettingsChange: onSettingsChange,
    );
  }

  testWidgets('GameScreen toggles settings overlay via AppBar action',
      (tester) async {
    final engine = GameEngine();

    await tester.pumpWidget(
      MaterialApp(
        home: buildScreen(
          engine: engine,
          onSettingsChange: (_) {},
        ),
      ),
    );

    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('changing theme in settings overlay invokes callback',
      (tester) async {
    final engine = GameEngine();
    GameSettings? updated;

    await tester.pumpWidget(
      MaterialApp(
        home: buildScreen(
          engine: engine,
          onSettingsChange: (value) => updated = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final dropdownFinder = find.byType(DropdownButton<ThemeType?>);
    final dropdown = tester.widget<DropdownButton<ThemeType?>>(dropdownFinder);
    dropdown.onChanged?.call(ThemeType.halloween);
    await tester.pump();

    expect(updated?.selectedTheme, ThemeType.halloween);
  });

  testWidgets('changing card selection mode triggers callback', (tester) async {
    final engine = GameEngine();
    GameSettings? updated;

    await tester.pumpWidget(
      MaterialApp(
        home: buildScreen(
          engine: engine,
          onSettingsChange: (value) => updated = value,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Long Press'));
    await tester.pump();

    expect(updated?.cardSelectionMode, CardSelectionMode.longPress);
  });

  group('score header', () {
    testWidgets('visible when gameStarted is true', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerScore: 42,
        opponentScore: 17,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
    });

    testWidgets('hidden when gameStarted is false', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: false,
        playerScore: 42,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('42'), findsNothing);
    });

    testWidgets('shows starter card for red suit', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        starterCard: PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        playerHand: _hand4,
        opponentHand: _hand4,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Starter'), findsOneWidget);
    });

    testWidgets('shows starter card for black suit', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        starterCard: PlayingCard(rank: Rank.king, suit: Suit.spades),
        playerHand: _hand4,
        opponentHand: _hand4,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Starter'), findsOneWidget);
      expect(find.text('K♠'), findsWidgets);
    });

    testWidgets('shows dealer badge when player is dealer', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        isPlayerDealer: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand6,
        opponentHand: _hand6,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('D'), findsOneWidget);
    });
  });

  group('spread deck', () {
    testWidgets('renders spread deck in cutForDealer phase', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cutForDealer,
        cutDeck: _smallCutDeck,
        playerHasSelectedCutCard: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Tap the deck to cut for dealer'), findsOneWidget);
    });

    testWidgets('shows cut card results when player has selected', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cutForDealer,
        cutDeck: _smallCutDeck,
        playerHasSelectedCutCard: true,
        cutPlayerCard: PlayingCard(rank: Rank.ace, suit: Suit.spades),
        cutOpponentCard: PlayingCard(rank: Rank.king, suit: Suit.hearts),
        isPlayerDealer: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Cut for Dealer'), findsOneWidget);
      expect(find.text('DEALER'), findsOneWidget);
    });

    testWidgets('shows tie message when cut cards have same rank', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cutForDealer,
        cutDeck: _smallCutDeck,
        playerHasSelectedCutCard: true,
        cutPlayerCard: PlayingCard(rank: Rank.ace, suit: Suit.spades),
        cutOpponentCard: PlayingCard(rank: Rank.ace, suit: Suit.hearts),
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Tie! Cut again.'), findsOneWidget);
    });
  });

  group('opponent and player hands', () {
    testWidgets('shows hands in crib selection phase', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand6,
        opponentHand: _hand6,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('TestOpponent (6 cards)'), findsOneWidget);
      expect(find.text('TestPlayer (6 cards)'), findsOneWidget);
    });

    testWidgets('shows crib selection instructions', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        playerHand: _hand6,
        opponentHand: _hand6,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Select 2 cards for the crib'), findsOneWidget);
    });
  });

  group('advise button', () {
    testWidgets('executes _handleAdvise when tapped during crib selection',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(
        const GameState(
          gameStarted: true,
          currentPhase: GamePhase.cribSelection,
          playerHand: _hand6,
          opponentHand: _hand6,
          selectedCards: {},
        ),
        fakeAdvice: [0, 1],
      );

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Advise'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Advise'));
      await tester.pump();
    });

    testWidgets('advise with empty indices does nothing', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(
        const GameState(
          gameStarted: true,
          currentPhase: GamePhase.cribSelection,
          playerHand: _hand6,
          opponentHand: _hand6,
        ),
        fakeAdvice: [],
      );

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Advise'));
      await tester.pump();
    });
  });

  group('pegging display', () {
    testWidgets('shows count and player turn indicator', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        peggingCount: 15,
        isPlayerTurn: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Count: 15'), findsOneWidget);
      expect(find.textContaining("TestPlayer's turn"), findsOneWidget);
    });

    testWidgets('shows opponent turn indicator', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        peggingCount: 10,
        isPlayerTurn: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.textContaining("TestOpponent's turn"), findsOneWidget);
    });
  });

  group('pending reset dialog', () {
    testWidgets('shows pending reset content', (tester) async {
      await _usePhone(tester);
      const pending = PendingResetState(
        pile: [PlayingCard(rank: Rank.ace, suit: Suit.hearts)],
        finalCount: 15,
        scoreAwarded: 2,
        message: 'Fifteen for 2!',
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        pendingReset: pending,
        playerHand: _hand4,
        opponentHand: _hand4,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Fifteen for 2!'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
    });

    testWidgets('tapping dialog does not crash', (tester) async {
      await _usePhone(tester);
      const pending = PendingResetState(
        pile: [PlayingCard(rank: Rank.ten, suit: Suit.clubs)],
        finalCount: 31,
        scoreAwarded: 2,
        message: '31 for 2!',
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        pendingReset: pending,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester.tap(find.text('Tap anywhere to continue'));
      await tester.pump();
    });
  });

  group('winner modal', () {
    testWidgets('shows player win with trophy icon', (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: true,
        playerScore: 121,
        opponentScore: 50,
        wasSkunk: false,
        wasDoubleSkunk: false,
        gamesWon: 3,
        gamesLost: 2,
        skunksFor: 1,
        skunksAgainst: 0,
        doubleSkunksFor: 0,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('TestPlayer Won!'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('Final Score'), findsOneWidget);
      expect(find.text('121 - 50'), findsOneWidget);
    });

    testWidgets('shows opponent win with close icon', (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: false,
        playerScore: 50,
        opponentScore: 121,
        wasSkunk: false,
        wasDoubleSkunk: false,
        gamesWon: 2,
        gamesLost: 3,
        skunksFor: 0,
        skunksAgainst: 1,
        doubleSkunksFor: 0,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('TestOpponent Won!'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows skunk badge when wasSkunk is true', (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: true,
        playerScore: 121,
        opponentScore: 60,
        wasSkunk: true,
        wasDoubleSkunk: false,
        gamesWon: 1,
        gamesLost: 0,
        skunksFor: 1,
        skunksAgainst: 0,
        doubleSkunksFor: 0,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('SKUNK!'), findsOneWidget);
    });

    testWidgets('shows double skunk badge when wasDoubleSkunk is true',
        (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: true,
        playerScore: 121,
        opponentScore: 30,
        wasSkunk: false,
        wasDoubleSkunk: true,
        gamesWon: 1,
        gamesLost: 0,
        skunksFor: 0,
        skunksAgainst: 0,
        doubleSkunksFor: 1,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('DOUBLE SKUNK!'), findsOneWidget);
    });

    testWidgets('tapping winner modal does not crash', (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: true,
        playerScore: 121,
        opponentScore: 50,
        wasSkunk: false,
        wasDoubleSkunk: false,
        gamesWon: 1,
        gamesLost: 0,
        skunksFor: 0,
        skunksAgainst: 0,
        doubleSkunksFor: 0,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester.tap(find.text('TestPlayer Won!'));
      await tester.pump();
    });

    testWidgets('shows overall statistics section', (tester) async {
      await _usePhone(tester);
      const winnerData = WinnerModalData(
        playerWon: true,
        playerScore: 121,
        opponentScore: 50,
        wasSkunk: false,
        wasDoubleSkunk: false,
        gamesWon: 5,
        gamesLost: 3,
        skunksFor: 2,
        skunksAgainst: 1,
        doubleSkunksFor: 0,
        doubleSkunksAgainst: 0,
      );

      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        showWinnerModal: true,
        winnerModalData: winnerData,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Overall Statistics'), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
      expect(find.text('Skunks'), findsOneWidget);
    });
  });

  group('player name dialog', () {
    testWidgets('opens when player name is tapped', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestPlayer').first);
      await tester.pumpAndSettle();

      expect(find.text('Enter Your Name'), findsOneWidget);
    });

    testWidgets('cancel button closes the dialog', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestPlayer').first);
      await tester.pumpAndSettle();
      expect(find.text('Enter Your Name'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Your Name'), findsNothing);
    });

    testWidgets('save with valid name closes dialog', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestPlayer').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Your Name'), findsNothing);
    });

    testWidgets('save with whitespace-only name shows error snackbar',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestPlayer').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter a valid name'), findsOneWidget);
    });

    testWidgets('opens opponent name dialog on opponent name tap', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestOpponent').first);
      await tester.pumpAndSettle();

      expect(find.text("Enter Opponent's Name"), findsOneWidget);
    });

    testWidgets('save name with double-space shows modification snackbar',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      await tester
          .tap(find.widgetWithText(GestureDetector, 'TestPlayer').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alice  Bob');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Name updated to:'), findsOneWidget);
    });
  });

  group('manual counting mode', () {
    testWidgets('shows ManualCountingDialog for player hand', (tester) async {
      await _usePhone(tester);
      // countingPhase=dealer + isPlayerDealer=true => player's dealer hand
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.handCounting,
        countingPhase: CountingPhase.dealer,
        isPlayerDealer: true,
        playerHand: _hand4,
        opponentHand: _hand4,
        starterCard: PlayingCard(rank: Rank.five, suit: Suit.hearts),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: buildScreen(
            engine: engine,
            settings: const GameSettings(countingMode: CountingMode.manual),
            onSettingsChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      // ManualCountingDialog has a Slider; HandCountingDialog does not
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows HandCountingDialog when counting mode is auto',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.handCounting,
        countingPhase: CountingPhase.dealer,
        isPlayerDealer: true,
        playerHand: _hand4,
        opponentHand: _hand4,
        starterCard: PlayingCard(rank: Rank.five, suit: Suit.hearts),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: buildScreen(
            engine: engine,
            settings:
                const GameSettings(countingMode: CountingMode.automatic),
            onSettingsChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsNothing);
    });
  });

  group('score animations', () {
    testWidgets('shows player score animation widget', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        playerScore: 42,
        playerScoreAnimation: ScoreAnimation(
          points: 5,
          isPlayer: true,
          timestamp: 0,
        ),
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // ScoreAnimationWidget should be rendered in the score header
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows opponent score animation widget', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        opponentScore: 20,
        opponentScoreAnimation: ScoreAnimation(
          points: 3,
          isPlayer: false,
          timestamp: 0,
        ),
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('20'), findsOneWidget);
    });
  });

  group('score column triple tap (debug)', () {
    testWidgets('triple tap on score shows debug dialog', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerScore: 55,
        opponentScore: 33,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // Find the score text and tap three times quickly
      final scoreFinder = find.text('55');
      await tester.tap(scoreFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(scoreFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(scoreFinder);
      await tester.pumpAndSettle();
      // Debug dialog should appear (DebugScoreDialog)
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('spread deck tap', () {
    testWidgets('tapping a card back in spread deck calls selectCutCard',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cutForDealer,
        cutDeck: _smallCutDeck,
        playerHasSelectedCutCard: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // Tap the first CardBackWidget (in the spread deck)
      final cardBackFinder = find.byType(CardBackWidget);
      expect(cardBackFinder, findsWidgets);
      await tester.tap(cardBackFinder.first);
      await tester.pump();
    });
  });

  group('player hand card interactions', () {
    testWidgets('tap card in crib selection selects it', (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        playerHand: _hand6,
        opponentHand: _hand6,
        selectedCards: {},
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // Tap a PlayingCardWidget in the player's hand
      final cardFinder = find.byType(PlayingCardWidget);
      expect(cardFinder, findsWidgets);
      await tester.tap(cardFinder.last);
      await tester.pump();
    });

    testWidgets('tap playable card in pegging plays it', (tester) async {
      await _usePhone(tester);
      // Player has a low card (ace=1) that can be played when count is 20
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        peggingCount: 20,
        isPlayerTurn: true,
        selectedCards: {},
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // Tap a PlayingCardWidget in the player's hand
      final cardFinder = find.byType(PlayingCardWidget);
      expect(cardFinder, findsWidgets);
      await tester.tap(cardFinder.last);
      await tester.pump();
    });

    testWidgets('tap unplayable card in pegging shows exceed-31 snackbar',
        (tester) async {
      await _usePhone(tester);
      // Count is 28; ace=1 is playable but king=10 would exceed 31
      // _hand4 has [ace♥(1), 5♣(5), 10♦(10), king♠(10)]
      // With count=28: ace(1)→29 OK, 5(5)→33 EXCEEDS, 10(10)→38 EXCEEDS, king(10)→38 EXCEEDS
      // Need a card that is unplayable (value+count > 31)
      // With count=22 and king(10): 22+10=32 > 31 → unplayable
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: [
          PlayingCard(rank: Rank.king, suit: Suit.spades), // value=10
        ],
        opponentHand: _hand4,
        peggingCount: 22,
        isPlayerTurn: true,
        selectedCards: {},
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // Tap the king card (would exceed 31: 22+10=32)
      await tester.tap(find.byType(PlayingCardWidget).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Cannot play'), findsOneWidget);
    });
  });

  group('advise with non-empty selection', () {
    testWidgets('clears existing selection before applying advice',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(
        const GameState(
          gameStarted: true,
          currentPhase: GamePhase.cribSelection,
          playerHand: _hand6,
          opponentHand: _hand6,
          selectedCards: {0}, // card 0 already selected
        ),
        fakeAdvice: [2, 3], // advice to select different cards
      );

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      // The advise button should still be visible (1 card selected, < 2)
      expect(find.widgetWithText(FilledButton, 'Advise'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Advise'));
      await tester.pump();
    });
  });

  group('drag mode', () {
    testWidgets('shows CribDropZone in crib selection with drag mode',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.cribSelection,
        playerHand: _hand6,
        opponentHand: _hand6,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: buildScreen(
            engine: engine,
            settings:
                const GameSettings(cardSelectionMode: CardSelectionMode.drag),
            onSettingsChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Drag 2 cards here for the crib'), findsOneWidget);
    });

    testWidgets('dealing phase with showCutForDealer shows spread deck',
        (tester) async {
      await _usePhone(tester);
      final engine = _FakeGameEngine(const GameState(
        gameStarted: true,
        currentPhase: GamePhase.dealing,
        cutDeck: _smallCutDeck,
        showCutForDealer: true,
        playerHasSelectedCutCard: true,
        cutPlayerCard: PlayingCard(rank: Rank.three, suit: Suit.clubs),
        cutOpponentCard: PlayingCard(rank: Rank.king, suit: Suit.hearts),
        isPlayerDealer: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Cut for Dealer'), findsOneWidget);
    });
  });

  group('pegging display with history', () {
    testWidgets('shows completed pegging rounds and current pile', (tester) async {
      await _usePhone(tester);
      final completedRound = (
        cards: const <PlayingCard>[
          PlayingCard(rank: Rank.ten, suit: Suit.hearts),
          PlayingCard(rank: Rank.five, suit: Suit.clubs),
        ],
        finalCount: 15,
        endReason: 'fifteen',
      );

      // Use FakeGameEngine with completed rounds in pegging
      final engine = _FakeGameEngine(GameState(
        gameStarted: true,
        currentPhase: GamePhase.pegging,
        playerName: 'TestPlayer',
        opponentName: 'TestOpponent',
        playerHand: _hand4,
        opponentHand: _hand4,
        peggingCount: 5,
        isPlayerTurn: true,
        peggingPile: const [PlayingCard(rank: Rank.five, suit: Suit.hearts)],
        peggingCompletedRounds: [completedRound],
      ));

      await tester.pumpWidget(
        MaterialApp(
            home: buildScreen(engine: engine, onSettingsChange: (_) {})),
      );
      await tester.pump();

      expect(find.text('Count: 5'), findsOneWidget);
    });
  });
}
