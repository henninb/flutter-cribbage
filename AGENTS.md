# Repository Guidelines

## Project Structure & Module Organization
- Flutter entrypoint: `lib/main.dart`
- UI + app wiring: `lib/src/app.dart`, widgets under `lib/src/ui/`
- Game logic: `lib/src/game/` (`models`, `logic`, `engine`)
- Services: `lib/src/services/` (persistence, platform adapters)
- Tests: `test/` (pure Dart `flutter test`)
- Web runner: `web/`
- Assets: `assets/` (SVG/PNG art referenced in `pubspec.yaml`)

## Build, Test, and Development Commands
- Install deps: `flutter pub get`
- Run analyzer/tests: `flutter analyze`, `flutter test`
- Run the app: `flutter run -d chrome` or target-specific device (after running `flutter create . --platforms=android,ios,...` once)
- Hot reload / restart available through Flutter tooling (VS Code, Android Studio, CLI).

## Coding Style & Naming Conventions
- Language: Dart 3 (Flutter stable). Use `dart format` / `flutter format`.
- Files under `lib/src/game` follow lower_snake_case; classes use PascalCase; members use lowerCamelCase.
- Keep lines ≤ 100 characters when practical.
- UI widgets live under `lib/src/ui/**` and should be small/composable.
- Prefer immutable data objects with `copyWith` for state transitions.

## Testing Guidelines
- Use `flutter_test` for unit/group tests. File names end with `_test.dart`.
- Prioritize deterministic tests for pegging logic, scoring, and persistence boundaries.
- Run `flutter test` before sending PRs; add regression tests when fixing bugs.

## Commit & Pull Request Guidelines
- Messages: imperative mood, ≤ 72 chars (e.g., `engine: add pegging manager tests`).
- Include screenshots/GIFs in PR descriptions for UI changes (Flutter web/desktop is fine).
- Document new commands or assets in `readme.md` when relevant.

## Security & Configuration Tips
- Do not commit secrets or platform signing keys.
- Platform folders (android/ios/macos/windows/linux) can be regenerated via `flutter create` and may remain untracked locally.
