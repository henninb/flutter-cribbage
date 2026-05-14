# Flutter Cribbage

A full-featured Cribbage card game built with Flutter, playable on Android, iOS, Linux, macOS, Windows, and Web.

## Features

- Complete Cribbage ruleset: cut for dealer, crib selection, pegging, and hand counting
- AI opponent with strategic crib discard and pegging logic
- Animated cribbage board tracking scores to 121
- Automatic hand scoring with detailed point breakdowns (fifteens, pairs, runs, flush, nobs)
- Season- and holiday-aware dynamic themes (spring, summer, fall, winter, New Year, Valentine's Day, St. Patrick's Day, Independence Day, Halloween, Thanksgiving, Christmas, and more)
- Manual theme override via settings
- Persistent game stats: wins, losses, skunks, double skunks
- Configurable card selection: tap, long press, or drag
- Player name customization persisted across sessions

## Project Structure

```
lib/
  src/
    app.dart                      # App entry point and provider setup
    game/
      engine/
        game_engine.dart          # Core game controller (ChangeNotifier)
        game_state.dart           # Immutable game state
      logic/
        cribbage_scorer.dart      # Hand and pegging scoring
        deal_utils.dart           # Deck shuffling and dealing
        opponent_ai.dart          # AI discard and pegging strategy
        pegging_round_manager.dart# Pegging phase state machine
      models/
        card.dart                 # PlayingCard model
    models/
      game_settings.dart          # User preferences
      theme_models.dart           # Theme types and color schemes
    services/
      game_persistence.dart       # SharedPreferences persistence
      settings_repository.dart    # Settings load/save
    ui/
      screens/
        game_screen.dart          # Main game screen
        settings_screen.dart      # Settings screen
      theme/
        theme_calculator.dart     # Date-based theme selection
        theme_definitions.dart    # Theme color palettes
      widgets/
        action_bar.dart
        cribbage_board.dart       # Animated peg board
        debug_score_dialog.dart
        hand_counting_dialog.dart
        playing_card_widget.dart
        score_animation.dart
        theme_selector_bar.dart
        welcome_screen.dart
    utils/
      string_sanitizer.dart       # Input sanitization
```

## Prerequisites

- Flutter SDK (stable channel, Dart >= 3.3.0)
- For Android: Android SDK, `adb`, an emulator or physical device
- For iOS: Xcode (macOS only)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run on Linux desktop
./run-linux.sh

# Run on Android emulator (includes diagnostics if no emulator is running)
./run.sh
```

## Build

```bash
# Android APK (debug)
flutter build apk --debug

# Android APK (release)
flutter build apk --release

# Linux
flutter build linux

# Web
flutter build web
```

## Testing

```bash
# Run all unit and widget tests
flutter test

# Run tests with coverage
./test-coverage.sh

# Run a single test file
flutter test test/cribbage_scorer_test.dart
```

## Code Quality

```bash
# Static analysis
flutter analyze

# Verify formatting
dart format --set-exit-if-changed .
```

## CI/CD

GitHub Actions runs on every push and pull request to `main`:

1. **Static Analysis** — `dart format`, `flutter analyze`, `flutter test`, dependency audit
2. **Build APK** — produces a debug APK artifact (retained 7 days)

CodeQL security scanning runs separately via `.github/workflows/codeql.yml`. Dependency vulnerability alerts are handled by Dependabot.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (stable) |
| Language | Dart >= 3.3.0 |
| State management | `provider` + `ChangeNotifier` |
| Persistence | `shared_preferences` |
| Theming | Material 3 with custom `ThemeData` |
| Testing | `flutter_test`, `fake_async` |

## Dependencies

- `provider ^6.1.2` — state management
- `shared_preferences ^2.5.4` — local persistence
- `intl ^0.20.2` — date formatting for theme selection
- `path_provider ^2.1.5` — file system paths

## License

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for data handling details.
