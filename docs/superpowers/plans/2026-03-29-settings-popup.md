# Settings Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current application-style settings window with a compact popup-style settings panel that opens from the menu bar and closes automatically on outside click.

**Architecture:** Keep `PreferencesView` as SwiftUI content and move settings presentation into a dedicated AppKit presenter. Route the menu bar Settings action through that presenter, remove the SwiftUI `Settings` scene, and tighten the preferences form so the hosted panel feels like a native utility popup instead of a standalone app window.

**Tech Stack:** Swift, SwiftUI, AppKit, XCTest, Xcode project build/test tooling

---

## File Structure

- Modify: `EyeBreak/App/EyeBreakApp.swift`
  - Remove the `Settings` scene and own a settings popup presenter alongside the reminder and break presenters.
- Create: `EyeBreak/UI/Preferences/SettingsPopupPresenter.swift`
  - Own the reusable compact `NSPanel`, host `PreferencesView`, and close the panel on loss of key status.
- Modify: `EyeBreak/UI/MenuBar/MenuBarContentView.swift`
  - Replace `openSettings` environment routing with an explicit closure to the popup presenter.
- Modify: `EyeBreak/UI/Preferences/PreferencesView.swift`
  - Reduce the default footprint and tighten spacing while keeping the form native.
- Create: `EyeBreakTests/SettingsPopupPresenterTests.swift`
  - Cover panel reuse, compact configuration, and auto-dismiss behavior.
- Modify: `EyeBreakTests/PreferencesViewTests.swift`
  - Update the expected native popup footprint.
- Modify: `README.md`
  - Update architecture notes to reflect the AppKit-backed settings popup.

### Task 1: Add failing presenter tests for compact popup behavior

**Files:**
- Create: `EyeBreakTests/SettingsPopupPresenterTests.swift`
- Test: `EyeBreakTests/SettingsPopupPresenterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import AppKit
import XCTest

@testable import EyeBreak

@MainActor
final class SettingsPopupPresenterTests: XCTestCase {
    func test_reusesSinglePanelAcrossRenders() {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let firstPanel = presenter.panel

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        XCTAssertNotNil(firstPanel)
        XCTAssertTrue(firstPanel === presenter.panel)
    }

    func test_usesCompactPanelConfigurationAndClosesOnResignKey() {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let panel = try XCTUnwrap(presenter.panel)

        XCTAssertEqual(panel.frame.width, PreferencesView.nativeWindowSize.width, accuracy: 0.5)
        XCTAssertEqual(panel.frame.height, PreferencesView.nativeWindowSize.height, accuracy: 0.5)
        XCTAssertFalse(panel.hidesOnDeactivate)

        panel.resignKey()

        XCTAssertFalse(panel.isVisible)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/SettingsPopupPresenterTests
```

Expected: FAIL because `SettingsPopupPresenter` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```swift
import AppKit
import SwiftUI

@MainActor
final class SettingsPopupPresenter: NSObject, NSWindowDelegate {
    private(set) var panel: NSPanel?

    func render(
        isPresented: Bool,
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        if isPresented {
            let panel = makePanelIfNeeded()
            panel.contentView = NSHostingView(
                rootView: PreferencesView(
                    settings: settings,
                    onSave: onSave,
                    onLaunchAtLoginChange: onLaunchAtLoginChange
                )
            )
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            panel?.orderOut(nil)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
    }

    private func makePanelIfNeeded() -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: PreferencesView.nativeWindowSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        self.panel = panel
        return panel
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/SettingsPopupPresenterTests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add EyeBreak/UI/Preferences/SettingsPopupPresenter.swift EyeBreakTests/SettingsPopupPresenterTests.swift
git commit -m "feat: add settings popup presenter"
```

### Task 2: Route the menu bar settings action through the presenter

**Files:**
- Modify: `EyeBreak/App/EyeBreakApp.swift`
- Modify: `EyeBreak/UI/MenuBar/MenuBarContentView.swift`
- Test: `EyeBreakTests/MenuBarContentViewTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
@MainActor
func test_settingsButtonInvokesInjectedSettingsAction() {
    var didOpenSettings = false
    let model = AppModel.makeForTests()
    let view = MenuBarRootView(
        model: model,
        quit: {},
        openSettingsOverride: { didOpenSettings = true }
    )

    view.openSettingsWindow()

    XCTAssertTrue(didOpenSettings)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/MenuBarContentViewTests/test_settingsButtonInvokesInjectedSettingsAction
```

Expected: FAIL because the app still depends on the `Settings` scene path.

- [ ] **Step 3: Write minimal implementation**

```swift
// EyeBreakApp.swift
private let settingsPopupPresenter = SettingsPopupPresenter()
@State private var isSettingsPopupPresented = false

MenuBarExtra("EyeBreak", systemImage: "eye") {
    MenuBarRootView(
        model: appModel,
        quit: { NSApp.terminate(nil) },
        openSettingsOverride: { isSettingsPopupPresented = true }
    )
}
.onChange(of: isSettingsPopupPresented, initial: true) { _, isPresented in
    settingsPopupPresenter.render(
        isPresented: isPresented,
        settings: appModel.settings,
        onSave: appModel.updateSettings,
        onLaunchAtLoginChange: appModel.setLaunchAtLogin
    )
}

// remove the Settings scene
```

```swift
// MenuBarContentView.swift
func openSettingsWindow() {
    if let openSettingsOverride {
        openSettingsOverride()
        return
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/MenuBarContentViewTests/test_settingsButtonInvokesInjectedSettingsAction
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add EyeBreak/App/EyeBreakApp.swift EyeBreak/UI/MenuBar/MenuBarContentView.swift EyeBreakTests/MenuBarContentViewTests.swift
git commit -m "feat: route settings through popup presenter"
```

### Task 3: Make the preferences layout compact and popup-sized

**Files:**
- Modify: `EyeBreak/UI/Preferences/PreferencesView.swift`
- Modify: `EyeBreakTests/PreferencesViewTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
func test_prefersCompactPopupFootprint() {
    let size = PreferencesView.nativeWindowSize

    XCTAssertEqual(size.width, 360, accuracy: 0.5)
    XCTAssertEqual(size.height, 250, accuracy: 0.5)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/PreferencesViewTests/test_prefersCompactPopupFootprint
```

Expected: FAIL because the current size is still `480x330`.

- [ ] **Step 3: Write minimal implementation**

```swift
// PreferencesView.swift
static let nativeWindowSize = CGSize(width: 360, height: 250)

.padding(.horizontal, 2)
.padding(.vertical, 4)
.frame(
    minWidth: Self.nativeWindowSize.width,
    minHeight: Self.nativeWindowSize.height,
    alignment: .topLeading
)
```

```swift
private func numericFieldRow(
    title: String,
    text: Binding<String>,
    unit: String,
    field: Field
) -> some View {
    LabeledContent(title) {
        HStack(spacing: 4) {
            TextField("", text: text)
                .frame(width: 48)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/PreferencesViewTests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add EyeBreak/UI/Preferences/PreferencesView.swift EyeBreakTests/PreferencesViewTests.swift
git commit -m "fix: compact settings popup layout"
```

### Task 4: Keep the popup in sync and document the architecture change

**Files:**
- Modify: `EyeBreak/App/EyeBreakApp.swift`
- Modify: `README.md`
- Test: `EyeBreakTests/SettingsPopupPresenterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
func test_updatesHostedPreferencesViewWhenSettingsChange() {
    let presenter = SettingsPopupPresenter()
    var settings = AppSettings.default

    presenter.render(
        isPresented: true,
        settings: settings,
        onSave: { _ in },
        onLaunchAtLoginChange: { _ in nil }
    )

    settings.idleThreshold = 9

    presenter.render(
        isPresented: true,
        settings: settings,
        onSave: { _ in },
        onLaunchAtLoginChange: { _ in nil }
    )

    let hostingView = presenter.panel?.contentView as? NSHostingView<PreferencesView>

    XCTAssertNotNil(hostingView)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/SettingsPopupPresenterTests/test_updatesHostedPreferencesViewWhenSettingsChange
```

Expected: FAIL if the presenter is recreating hosted content incorrectly or not exposing the hosted view type.

- [ ] **Step 3: Write minimal implementation**

```swift
private var hostingView: NSHostingView<PreferencesView>?

func render(
    isPresented: Bool,
    settings: AppSettings,
    onSave: @escaping (AppSettings) -> Void,
    onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
) {
    if isPresented {
        let panel = makePanelIfNeeded()
        let rootView = PreferencesView(
            settings: settings,
            onSave: onSave,
            onLaunchAtLoginChange: onLaunchAtLoginChange
        )

        if let hostingView {
            hostingView.rootView = rootView
        } else {
            let hostingView = NSHostingView(rootView: rootView)
            panel.contentView = hostingView
            self.hostingView = hostingView
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    } else {
        panel?.orderOut(nil)
    }
}
```

```md
## Architecture

- SwiftUI drives the app model, menu content, reminder view content, break view content, and preferences form.
- AppKit remains isolated to thin presenters for the reminder popup, break overlay, and compact settings popup, where macOS window behavior still needs precise control.
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' -only-testing:EyeBreakTests/SettingsPopupPresenterTests -only-testing:EyeBreakTests/PreferencesViewTests -only-testing:EyeBreakTests/MenuBarContentViewTests
xcodebuild -project EyeBreak.xcodeproj -scheme EyeBreak -destination 'platform=macOS,arch=arm64' build
```

Expected: PASS and `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add EyeBreak/App/EyeBreakApp.swift EyeBreak/UI/Preferences/SettingsPopupPresenter.swift EyeBreakTests/SettingsPopupPresenterTests.swift README.md
git commit -m "docs: document settings popup architecture"
```

## Self-Review

- Spec coverage: the plan covers the AppKit presenter, menu-bar routing, compact preferences layout, auto-dismiss behavior, presenter reuse, and README updates.
- Placeholder scan: all tasks include concrete files, commands, and code targets; there are no `TODO` or `TBD` markers.
- Type consistency: the plan consistently uses `SettingsPopupPresenter`, `PreferencesView.nativeWindowSize`, `openSettingsOverride`, and `render(isPresented:settings:onSave:onLaunchAtLoginChange:)`.
