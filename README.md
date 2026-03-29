# EyeBreak

EyeBreak is a native macOS menu bar app that nudges you to take eye breaks without interrupting active work. It tracks real active time, waits until you go idle, then starts a clean full-screen break on macOS.

## Why It Feels Different

- Counts active computer use instead of simple wall-clock time.
- Reminds gently first, then waits for idle before starting the break.
- Rotates short and long breaks automatically.
- Lives in the menu bar and stays out of the way until it matters.

## Install, Build, Test, Lint, Release

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

Format the codebase in place:

```bash
swift-format format -ir EyeBreak EyeBreakTests
```

Check formatting without rewriting files:

```bash
swift-format lint -r EyeBreak EyeBreakTests
```

Run SwiftLint:

```bash
swiftlint lint
```

Create a GitHub release artifact by pushing a version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Tagged releases build the app in Release configuration, package `EyeBreak.app` into `EyeBreak-macOS.zip`, upload the zip as a workflow artifact, and publish it as an unsigned GitHub prerelease asset.

## Architecture

EyeBreak stays small by keeping scheduling logic in plain Swift and treating UI surfaces as thin layers over shared app state.

- `EyeBreakApp` is the SwiftUI `MenuBarExtra` entry point and app shell.
- `AppModel` exposes coordinator state and actions to SwiftUI views.
- `AppCoordinator` owns the app snapshot and applies heartbeat, reminder, break, and sleep/wake transitions.
- `BreakScheduler` tracks active-time progress and decides when reminders should appear.
- `ReminderPopupPresenter` is the AppKit bridge for the top-of-screen reminder banner while `ReminderPopupView` keeps the content in SwiftUI.
- `BreakOverlayPresenter` is the AppKit bridge that renders the full-screen break experience.

`AppSnapshot` and `AppSettings` stay the source of truth, so UI reacts to shared state instead of maintaining its own timing rules.

## How Breaks Flow

1. `Heartbeat` ticks the coordinator on a fixed cadence.
2. The coordinator checks the current idle duration and advances the scheduler only when the app is actively in use.
3. Once active time reaches the configured interval, the scheduler enters `waitingForIdle` and shows the reminder popup.
4. If you skip the reminder, the scheduler resets active progress.
5. If idle time reaches the configured threshold while the app is waiting, the coordinator starts a break session and shows the break overlay.
6. Break timing is tracked separately by `BreakSessionManager`, which handles short and long break selection and countdown.

The reminder popup uses a non-activating AppKit panel hosted with SwiftUI content so it can behave like a lightweight macOS banner instead of a normal app window. The break overlay is also AppKit-backed so it can cover the selected screen reliably.

## Limitations

- Launch-at-login behavior can differ in unsigned debug builds, even though the preference is still saved.
- The break overlay still uses AppKit for reliable full-screen behavior across displays.
- The release workflow produces a GitHub-ready artifact, not a notarized build.

## Release Notes

- Pull requests and pushes run GitHub Actions checks for formatting, linting, build, and tests.
- Version tags publish an unsigned prerelease zip that is ready for download and manual testing.
- Because the artifact is not notarized, macOS Gatekeeper may warn or block it on a default system.
