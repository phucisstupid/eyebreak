# Repository Guidelines

## Project Structure & Module Organization
`EyeBreak/` contains the macOS app source. Keep responsibilities narrow:
- `App/` app entry, coordinator, app lifecycle, heartbeat
- `Core/` scheduling, state, settings, and plain Swift domain logic
- `Infrastructure/` system integrations such as idle-time detection and launch-at-login
- `UI/` menu bar, popup, break overlay, and preferences surfaces
- `Resources/` app assets and plist data

Tests live in `EyeBreakTests/`. The Xcode project is `EyeBreak.xcodeproj`.

## Build, Test, and Development Commands
Open the project in Xcode:

```bash
open EyeBreak.xcodeproj
```

Build from Terminal:

```bash
xcodebuild -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS' build
```

Run the full test suite:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS'
```

Run a focused test case while iterating:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS' -only-testing:EyeBreakTests/AppCoordinatorTests
```

## Coding Style & Naming Conventions
Use Swift with 4-space indentation and standard Xcode formatting. Prefer explicit, descriptive names such as `BreakScheduler`, `ReminderPopupPresenter`, and `SystemIdleTimeProvider`. Keep SwiftUI views small and AppKit usage isolated to presenters or platform wrappers. Add comments only when intent is not obvious from the code.

## Testing Guidelines
Use XCTest in `EyeBreakTests/`. Favor small, behavior-focused tests for scheduling, idle detection, presenter geometry, and menu-state formatting. Name tests with descriptive `test...` methods that state the behavior under test. When changing timing or window behavior, add or update regression coverage.

## Commit & Pull Request Guidelines
Match the existing history: use short imperative prefixes such as `feat:`, `fix:`, `docs:`, and `chore:`. Keep commits focused on one concern. Pull requests should include:
- a brief summary of the user-visible change
- verification commands and results
- screenshots or recordings for menu, popup, overlay, or preferences changes
- linked issues or context when relevant

## Architecture Notes
This app favors simple composition over large view models. Keep domain logic testable in plain Swift types, and treat menu bar, popup, and overlay presentation as thin UI layers over shared app state.
