# Flutter Cribbage Migration Plan
## Updating Flutter App to Match Android App

### Executive Summary
This document outlines the comprehensive plan to update the Flutter cribbage app to match all features and functionality of the Android cribbage app located at `~/projects/github.com/henninb/android-cribbage`.

---

## Current State Analysis

### Flutter App (Current)
- **Architecture**: Provider pattern with single GameEngine
- **UI**: Single screen with all game phases
- **Features**: Complete core cribbage gameplay
- **Screens**: 1 (GameScreen)
- **Themes**: Basic Material 3 with teal seed color
- **Scoring**: Automatic only
- **Settings**: None

### Android App (Target)
- **Architecture**: MVVM with ViewModel + multiple State Managers
- **UI**: Multi-screen with zone-based layout (no scrolling)
- **Features**: Core gameplay + advanced features
- **Screens**: 3+ (WelcomeScreen, CribbageMainScreen, SettingsScreen)
- **Themes**: 17 themes (4 seasonal + 13 holidays) with auto-detection
- **Scoring**: Automatic OR Manual (user choice)
- **Settings**: Card selection mode, Counting mode

---

## Feature Gap Analysis

### ✅ Features Already in Flutter App
1. Complete cribbage scoring (fifteens, pairs, runs, flushes, nobs)
2. Pegging phase with proper GO logic
3. Hand counting phase
4. Opponent AI with smart strategies
5. Game win detection (121 points)
6. Skunk detection (opponent < 91)
7. Game statistics persistence (W-L, skunks)
8. Card dealing and crib selection
9. Cut for dealer

### ❌ Missing Features (Need to Add)

#### 1. **Welcome Screen**
- Displayed before game starts
- App branding with icon/logo
- Welcome message
- Instructions to start game

#### 2. **Settings Screen**
- Card Selection Mode setting:
  - TAP (default)
  - LONG_PRESS
  - DRAG (drag to discard area)
- Counting Mode setting:
  - AUTOMATIC (default)
  - MANUAL (player enters points)
- Persistent settings storage

#### 3. **Manual Counting Mode**
- Dialog for player to enter points manually
- Validation against correct score
- Feedback messages (correct/incorrect)
- Educational tool for learning scoring

#### 4. **Seasonal/Holiday Theme System**
- **17 themes total**:
  - Spring, Summer, Fall, Winter (seasonal)
  - New Year, MLK Day, Valentine's Day, Presidents Day
  - Pi Day, Ides of March, St. Patrick's Day
  - Memorial Day, Independence Day, Labor Day
  - Halloween, Thanksgiving, Christmas
- Automatic theme detection based on current date
- Theme selector bar with emoji icons
- Manual theme override capability
- Each theme has custom colors for:
  - Primary/secondary colors
  - Background/surface
  - Card backs
  - Board colors
  - Accent colors

#### 5. **Cribbage Board Visualization**
- Visual representation of the 121-point board
- Pegs showing player/opponent positions
- Traditional cribbage board layout
- Always visible at bottom of screen

#### 6. **Cut Card Display Modal**
- Modal/dialog showing the starter card
- Appears after crib selection, before pegging
- "Continue" button to proceed
- Highlights if Jack (His Heels = 2 points to dealer)

#### 7. **Score Animations**
- Animated score changes when points are awarded
- Visual feedback for scoring events
- Clear indication of points gained

#### 8. **31 Banner Enhancement**
- More prominent visual banner when 31 is reached
- Shows points awarded
- Better visual feedback

#### 9. **Double Skunk Tracking**
- Track when opponent scores < 61 points (double skunk)
- Separate statistics for double skunks
- Display in winner modal and stats

#### 10. **Bug Report Functionality**
- Email bug report with complete game state
- Includes all hands, scores, game phase
- Device and app version info
- Pre-formatted email template

#### 11. **Debug Score Dialog**
- Hidden feature activated by triple-tap on score header
- Adjust player/opponent scores for testing
- Only available in debug builds

#### 12. **UI Improvements**
- **Zone-based Layout** (no scrolling):
  - Zone 0: Theme selector bar (top)
  - Zone 1: Compact score header
  - Zone 2: Game area (flexible height)
  - Zone 3: Action bar (bottom)
  - Zone 4: Cribbage board (bottom)
- **Compact Score Header**: Shows scores, dealer, starter card
- **Action Bar**: Context-sensitive buttons at bottom
- **Better Card Visuals**: More polished card designs
- **Welcome Screen**: Shown initially instead of "Start Game" button

---

## Migration Strategy

### Phase 1: Project Structure & Architecture
**Goal**: Set up proper architecture and file structure

#### Tasks:
1. Create new directory structure:
   ```
   lib/src/
   ├── models/
   │   ├── game_settings.dart (new)
   │   └── theme_models.dart (new)
   ├── services/
   │   ├── settings_repository.dart (new)
   │   └── theme_service.dart (new)
   ├── ui/
   │   ├── screens/
   │   │   ├── welcome_screen.dart (new)
   │   │   ├── settings_screen.dart (new)
   │   │   └── game_screen.dart (existing, refactor)
   │   ├── widgets/
   │   │   ├── cribbage_board.dart (new)
   │   │   ├── theme_selector_bar.dart (new)
   │   │   ├── action_bar.dart (new)
   │   │   ├── score_header.dart (new)
   │   │   ├── cut_card_dialog.dart (new)
   │   │   ├── manual_counting_dialog.dart (new)
   │   │   ├── debug_score_dialog.dart (new)
   │   │   └── winner_modal.dart (refactor)
   │   └── theme/
   │       ├── seasonal_themes.dart (new)
   │       └── theme_definitions.dart (new)
   ```

2. Update dependencies in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     provider: ^6.1.2
     shared_preferences: ^2.2.3
     intl: ^0.19.0  # For date handling
     url_launcher: ^6.3.0  # For bug report emails
   ```

### Phase 2: Theme System
**Goal**: Implement complete theme system

#### Tasks:
1. **Create theme models** (`lib/src/models/theme_models.dart`):
   - `ThemeType` enum (17 values)
   - `ThemeColors` data class
   - `CribbageTheme` data class

2. **Create theme definitions** (`lib/src/ui/theme/theme_definitions.dart`):
   - Define all 17 themes with color schemes
   - Port from Android's `ThemeDefinitions.kt`

3. **Create theme calculator** (`lib/src/ui/theme/seasonal_themes.dart`):
   - `ThemeCalculator` class
   - Date-based theme detection
   - Holiday calculation logic
   - Seasonal fallback

4. **Create theme selector bar** (`lib/src/ui/widgets/theme_selector_bar.dart`):
   - Horizontal scrollable list of theme icons
   - Current theme indicator
   - Theme change callback
   - Settings button

5. **Update app.dart**:
   - Add theme provider/state
   - Load current theme on startup
   - Apply theme to MaterialApp

### Phase 3: Settings System
**Goal**: Add settings screen and persistence

#### Tasks:
1. **Create game settings model** (`lib/src/models/game_settings.dart`):
   - `CardSelectionMode` enum (TAP, LONG_PRESS, DRAG)
   - `CountingMode` enum (AUTOMATIC, MANUAL)
   - `GameSettings` data class

2. **Create settings repository** (`lib/src/services/settings_repository.dart`):
   - Load/save settings via SharedPreferences
   - Default values
   - Settings change notifications

3. **Create settings screen** (`lib/src/ui/screens/settings_screen.dart`):
   - Card selection mode picker
   - Counting mode picker
   - Back button
   - Save on change

4. **Update GameEngine**:
   - Add settings property
   - Respect card selection mode
   - Implement manual counting flow

### Phase 4: Welcome Screen
**Goal**: Add welcome screen shown before game starts

#### Tasks:
1. **Create welcome screen** (`lib/src/ui/screens/welcome_screen.dart`):
   - App icon/logo (playing card emoji)
   - "Cribbage" title
   - "Classic Card Game" subtitle
   - Welcome message card
   - Instructions to start
   - Themed background

2. **Update game flow**:
   - Show welcome screen when `gameStarted == false`
   - Hide welcome screen after "Start New Game"
   - Add navigation logic in main screen

### Phase 5: Manual Counting Mode
**Goal**: Implement manual counting feature

#### Tasks:
1. **Create manual counting dialog** (`lib/src/ui/widgets/manual_counting_dialog.dart`):
   - Show current hand being counted
   - Input field for points
   - Submit button
   - Validation logic
   - Feedback messages (correct/incorrect with actual score)

2. **Update GameEngine**:
   - Add `waitingForManualInput` state
   - Add `submitManualCount()` method
   - Validate user input against calculated score
   - Provide feedback

3. **Update hand counting flow**:
   - Check counting mode setting
   - If AUTOMATIC: show score breakdown (existing)
   - If MANUAL: show input dialog (new)

### Phase 6: Cribbage Board Visualization
**Goal**: Add visual cribbage board

#### Tasks:
1. **Create cribbage board widget** (`lib/src/ui/widgets/cribbage_board.dart`):
   - Traditional 121-point board layout
   - Two tracks (player and opponent)
   - Peg positions based on scores
   - Compact design for bottom of screen
   - Themed colors
   - Consider different layouts:
     - Traditional serpentine (3 rows of 40 + 1)
     - Vertical dual-track
     - Simplified linear

2. **Update main screen layout**:
   - Add board to bottom zone (always visible)
   - Adjust spacing

### Phase 7: UI Enhancements
**Goal**: Match Android UI quality and layout

#### Tasks:
1. **Create compact score header** (`lib/src/ui/widgets/score_header.dart`):
   - Player score with animation
   - Opponent score with animation
   - Dealer indicator
   - Starter card display (if available)
   - Triple-tap gesture for debug (debug builds only)

2. **Create action bar** (`lib/src/ui/widgets/action_bar.dart`):
   - Context-sensitive buttons based on phase
   - "Start New Game", "End Game", "Deal", etc.
   - Bug report button
   - Fixed position at bottom

3. **Create cut card dialog** (`lib/src/ui/widgets/cut_card_dialog.dart`):
   - Modal showing starter card
   - Large card display
   - "His Heels" indicator if Jack
   - "Continue to Pegging" button

4. **Refactor game screen** (`lib/src/ui/screens/game_screen.dart`):
   - Implement zone-based layout
   - Remove scrolling
   - Integrate new widgets
   - Clean separation of zones

5. **Enhance card displays**:
   - Better card styling
   - Suit symbols with proper colors
   - Card shadows/elevation
   - Selection animations

6. **Add score animations**:
   - Create score animation widget
   - Trigger on point awards
   - Smooth number transitions

### Phase 8: Additional Features
**Goal**: Add remaining features

#### Tasks:
1. **Double skunk tracking**:
   - Update GameState to track double skunks
   - Check for opponent < 61 on win
   - Update persistence to save/load double skunks
   - Display in winner modal

2. **Bug report functionality**:
   - Create bug report utility
   - Gather complete game state
   - Format email body
   - Use `url_launcher` to open email client
   - Add "Report Bug" button to action bar

3. **Debug score dialog** (`lib/src/ui/widgets/debug_score_dialog.dart`):
   - Show current scores
   - +/- buttons to adjust
   - Only in debug mode
   - Activated by triple-tap on score header

4. **Enhanced 31 banner**:
   - More prominent visual
   - Animated appearance
   - Shows points awarded
   - Dismiss button

### Phase 9: Testing & Polish
**Goal**: Ensure quality and compatibility

#### Tasks:
1. **Update tests**:
   - Add tests for new settings
   - Test theme calculator logic
   - Test manual counting validation
   - Widget tests for new screens

2. **Performance optimization**:
   - Optimize board rendering
   - Efficient theme switching
   - Minimize rebuilds

3. **Accessibility**:
   - Add semantic labels
   - Test screen reader support
   - Ensure sufficient color contrast

4. **Polish**:
   - Smooth transitions between screens
   - Consistent spacing and padding
   - Error handling
   - Loading states

### Phase 10: Documentation & Cleanup
**Goal**: Clean codebase and document changes

#### Tasks:
1. **Code cleanup**:
   - Remove unused code
   - Consistent formatting
   - Add code comments
   - Organize imports

2. **Documentation**:
   - Update README.md
   - Add feature documentation
   - Update CLAUDE.md with new guidelines
   - Create user guide

3. **Final testing**:
   - Full gameplay test
   - All theme variations
   - All settings combinations
   - Bug report flow

---

## Implementation Order

### Priority 1 (Core Features)
1. Project structure setup
2. Theme system
3. Settings screen and persistence
4. Welcome screen
5. Manual counting mode

### Priority 2 (UI/UX)
6. Cribbage board visualization
7. UI enhancements (zone layout, action bar, score header)
8. Cut card dialog
9. Score animations

### Priority 3 (Nice-to-Have)
10. Double skunk tracking
11. Bug report functionality
12. Debug score dialog
13. Enhanced 31 banner

---

## Estimated Scope

### Files to Create: ~20 new files
### Files to Modify: ~5 existing files
### Lines of Code: ~2,500-3,000 new lines
### Dependencies to Add: 2 (intl, url_launcher)

---

## Migration Checklist

### Phase 1: Structure ☐
- [ ] Create new directory structure
- [ ] Add new dependencies
- [ ] Set up models package

### Phase 2: Themes ☐
- [ ] Theme models
- [ ] Theme definitions (17 themes)
- [ ] Theme calculator
- [ ] Theme selector bar
- [ ] Update app theme provider

### Phase 3: Settings ☐
- [ ] Settings model
- [ ] Settings repository
- [ ] Settings screen
- [ ] Settings persistence

### Phase 4: Welcome ☐
- [ ] Welcome screen widget
- [ ] Navigation logic
- [ ] Theme integration

### Phase 5: Manual Counting ☐
- [ ] Manual counting dialog
- [ ] Validation logic
- [ ] GameEngine updates
- [ ] Settings integration

### Phase 6: Board ☐
- [ ] Board widget
- [ ] Peg positioning logic
- [ ] Theme integration
- [ ] Layout integration

### Phase 7: UI ☐
- [ ] Score header
- [ ] Action bar
- [ ] Cut card dialog
- [ ] Zone-based layout
- [ ] Card enhancements
- [ ] Score animations

### Phase 8: Additional ☐
- [ ] Double skunk tracking
- [ ] Bug report utility
- [ ] Debug score dialog
- [ ] Enhanced 31 banner

### Phase 9: Testing ☐
- [ ] Unit tests
- [ ] Widget tests
- [ ] Integration tests
- [ ] Performance testing

### Phase 10: Cleanup ☐
- [ ] Code cleanup
- [ ] Documentation
- [ ] Final testing

---

## Success Criteria

The migration is complete when:
1. ✅ Flutter app has all 17 themes with auto-detection
2. ✅ Settings screen with card selection and counting modes
3. ✅ Welcome screen displays before game starts
4. ✅ Manual counting mode works with validation
5. ✅ Cribbage board visualizes scores
6. ✅ Zone-based UI matches Android layout
7. ✅ All new features tested
8. ✅ Code is clean and documented
9. ✅ No regressions in existing gameplay

---

## Notes

- **Maintain existing game logic**: The core scoring and game engine logic is already correct and tested. Don't break it!
- **Focus on UI/UX**: Most changes are additive (new screens, new widgets, new features)
- **Theme system is largest addition**: 17 themes with date-based detection is significant
- **Settings enable new modes**: Manual counting and card selection modes are new gameplay variations
- **KMM not required**: Android app uses Kotlin Multiplatform Mobile, but Flutter already handles cross-platform
- **Preserve simplicity**: Keep the clean architecture that already exists

---

## Questions for User

Before starting implementation:
1. Do you want all 17 themes, or a subset?
2. Is manual counting mode a must-have or nice-to-have?
3. What style of cribbage board visualization do you prefer?
4. Should we keep the single-screen approach or add navigation between screens?
5. Any specific features to prioritize or deprioritize?
