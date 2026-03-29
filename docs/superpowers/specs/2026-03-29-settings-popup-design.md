# Settings Popup Design

## Goal

Replace the current application-style Settings window with a compact popup-style settings panel that feels native to a menu bar app. The panel should open from the menu bar, stay visually lightweight, and close automatically when the user clicks outside it.

## Current Problem

The app currently uses a SwiftUI `Settings` scene. That gives standard macOS preferences behavior, but it feels like a separate application window instead of a lightweight menu bar utility surface. The existing preferences layout is also wider and taller than needed for the app’s small settings set.

## Proposed Approach

Use a dedicated AppKit-backed `SettingsPopupPresenter` and keep `PreferencesView` as SwiftUI content hosted inside it.

This keeps behavior and UI responsibilities separate:
- `PreferencesView` remains the SwiftUI form for editing settings.
- `SettingsPopupPresenter` owns window creation, reuse, focus behavior, and dismissal.
- `MenuBarContentView` triggers the presenter instead of calling SwiftUI `openSettings`.
- `EyeBreakApp` stops declaring a `Settings` scene for normal app use.

## Popup Behavior

The settings popup should:
- open from the menu bar Settings action
- present as a compact popup-style utility panel rather than a document window
- close automatically when the panel resigns key status or the user clicks outside it
- reuse a single panel instance to avoid flicker and duplicate windows
- activate cleanly from the menu bar without showing a full application-style preferences surface

The panel does not need special screen targeting. It only needs to feel like a lightweight, native popup for a menu bar app.

## Preferences Layout

`PreferencesView` should stay visually stock macOS and become denser:
- reduce the default window footprint from the current `480x330`
- tighten outer padding and section spacing
- keep grouped-form styling and semantic colors
- keep text-field numeric inputs and the launch-at-login toggle

The form should remain readable and accessible, but feel more like a compact utility sheet than a standalone settings page.

## Testing

Add focused regression coverage for:
- compact native settings footprint
- popup presenter reuse instead of re-creating windows
- auto-dismiss behavior on outside click or loss of key status
- menu bar settings action routing through the popup presenter

Verification should include focused tests for the presenter and preferences layout, followed by a full app build.

## Scope Boundaries

This change only affects settings presentation and layout. It does not change reminder scheduling, break behavior, popup reminder behavior, or the full-screen break overlay.
