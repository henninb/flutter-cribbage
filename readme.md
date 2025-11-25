# Cribbage (Flutter)

A full cribbage experience rebuilt in Flutter. The new implementation keeps the
original gameplay loop—cut for dealer, deal, crib selection, pegging, and hand
counting—while running with a single Dart codebase that is ready for Android,
iOS, web, and desktop targets.

## Highlights

- **Flutter + Material 3 UI** with responsive layout and score banners.
- **Pure Dart game engine** that ports the Kotlin logic (deck management,
  pegging round manager, scorer, and opponent AI).
- **Persistent match stats** backed by `SharedPreferences`.
- **Autonomous opponent pegging** using the migrated AI heuristics.
- **Unit tests** that cover the scorer and pegging round manager.

## Getting Started

```bash
# Fetch dependencies
flutter pub get

# Run unit tests
flutter test

# Launch the app (after creating platform shells)
flutter run -d chrome   # or any connected device
```

### Platform shells

The repo tracks the Dart sources and web runner. To target Android/iOS/desktop,
create the platform folders once (they can be regenerated safely):

```bash
flutter create . --platforms=android,ios,windows,linux,macos
```

This command keeps existing Dart/web files intact while generating the missing
platform scaffolding, Gradle wrappers, and Xcode projects.

## Project Structure

```
lib/
  main.dart               # App bootstrap + Provider wiring
  src/
    app.dart              # MaterialApp + theme
    game/
      engine/             # GameEngine + state models
      logic/              # Scorers, AI, deal utilities
      models/             # Card/rank/suit models
    services/             # SharedPreferences persistence adapter
    ui/                   # Widgets/screens
web/                      # Flutter web runner
assets/                   # Placeholder for card art / icons
```

## Gameplay Flow

1. **Start / Cut** – tap *Start Game*, then *Cut for Dealer* to simulate the
   initial cut. Drawn cards persist between sessions for continuity.
2. **Deal & select crib** – deal six cards to each player and pick two cards for
   the crib. The opponent AI uses the migrated heuristic to select its discards.
3. **Pegging** – play cards by tapping them. The opponent responds automatically
   using the ported pegging strategy. A *Go* button appears whenever you have no
   legal plays.
4. **Hand counting** – once pegging finishes, tap *Start Hand Counting* and walk
   through non-dealer, dealer, and crib scoring with detailed breakdowns.
5. **Match tracking** – wins/losses and skunks accumulate across games in local
   storage. Restart at any time via the app bar refresh icon.

## Debugging Features

### Debug Score Dialog (Debug Builds Only)

When running in debug mode, you can manually adjust scores for testing:

1. **Triple-tap** on either player's score number in the score header
2. A debug dialog will appear with +/- buttons
3. Adjust scores by 1 or 5 points using the controls
4. Click **Apply** to update the scores

This feature is automatically disabled in release builds and is useful for:
- Testing end-game scenarios
- Verifying skunk detection logic
- Debugging score-related issues
- Quick game state setup for testing

## Testing

Two focused suites ensure the Dart port stays faithful to the Kotlin logic:

- `test/cribbage_scorer_test.dart` – verifies detailed hand scoring and pegging
  windows.
- `test/pegging_round_manager_test.dart` – validates resets for GO and 31.

Run them via `flutter test`. Add additional coverage when modifying scoring or
pegging logic.

## Assets & Theming

The `assets/` directory is ready for SVG/PNG card art or icons. Add entries to
`pubspec.yaml` as assets are introduced. Material 3 color seed can be customized
from `src/app.dart`.

## Next Steps

- Flesh out platform-specific directories via `flutter create` (see above).
- Bring over vector assets/card illustrations from the Android project.
- Expand unit tests to cover the full engine as more behavior migrates.
