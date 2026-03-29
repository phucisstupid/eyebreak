import AppKit
import XCTest
import SwiftUI

@testable import EyeBreak

@MainActor
final class SettingsPopupPresenterTests: XCTestCase {
    func test_renderCreatesCompactPanelWithPreferencesView() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let panel = try XCTUnwrap(presenter.panel)
        XCTAssertEqual(panel.frame.size, PreferencesView.nativeWindowSize)
        XCTAssertNotNil(panel.contentView as? NSHostingView<PreferencesView>)
    }

    func test_renderWiresThePanelDelegateToThePresenter() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let panel = try XCTUnwrap(presenter.panel)
        XCTAssertTrue(panel.delegate === presenter)

        let delegate = try XCTUnwrap(panel.delegate as? SettingsPopupPresenter)
        delegate.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

        XCTAssertFalse(panel.isVisible)
    }

    func test_renderReusesTheSamePanelInstanceAcrossPresentations() {
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

        XCTAssertTrue(firstPanel === presenter.panel)
    }

    func test_renderReplacesTheContentViewOnEachPresentation() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)
        let firstContentView = try XCTUnwrap(panel.contentView)

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let secondContentView = try XCTUnwrap(panel.contentView)
        XCTAssertFalse(firstContentView === secondContentView)
        XCTAssertNotNil(secondContentView as? NSHostingView<PreferencesView>)
    }

    func test_renderRecreatesPreferencesViewWithUpdatedSettingsValues() throws {
        let presenter = SettingsPopupPresenter()
        let initialSettings = AppSettings(
            activeInterval: 20 * 60,
            shortBreakDuration: 20,
            longBreakDuration: 60,
            longBreakFrequency: 3,
            idleThreshold: 5,
            launchAtLogin: false
        )
        let updatedSettings = AppSettings(
            activeInterval: 45 * 60,
            shortBreakDuration: 30,
            longBreakDuration: 120,
            longBreakFrequency: 7,
            idleThreshold: 12,
            launchAtLogin: true
        )

        presenter.render(
            isPresented: true,
            settings: initialSettings,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let panel = try XCTUnwrap(presenter.panel)
        let firstHostingView = try XCTUnwrap(panel.contentView as? NSHostingView<PreferencesView>)
        XCTAssertEqual(
            extractedSettings(from: firstHostingView.rootView),
            initialSettings
        )

        presenter.render(
            isPresented: true,
            settings: updatedSettings,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let secondHostingView = try XCTUnwrap(panel.contentView as? NSHostingView<PreferencesView>)
        XCTAssertEqual(
            extractedSettings(from: secondHostingView.rootView),
            updatedSettings
        )
        XCTAssertEqual(
            extractedSettings(from: firstHostingView.rootView),
            initialSettings
        )
    }

    func test_renderCreatesANonClosablePanel() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)

        XCTAssertFalse(panel.styleMask.contains(.closable))
    }

    func test_renderPreservesTheExistingPanelOriginWhenReusingThePanel() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)
        panel.setFrameOrigin(NSPoint(x: 42, y: 84))

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        XCTAssertEqual(panel.frame.origin, NSPoint(x: 42, y: 84))
    }

    func test_renderOrdersPanelOutWhenPresentationIsDisabled() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)

        presenter.render(
            isPresented: false,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        XCTAssertFalse(panel.isVisible)
    }

    func test_windowDidResignKeyClosesThePanelButKeepsItForReuse() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)

        presenter.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

        XCTAssertTrue(presenter.panel === panel)
        XCTAssertFalse(panel.isVisible)
    }

    func test_renderDoesNotReopenAfterResignKeyUntilPresentationIsExplicitlyDisabledAndEnabledAgain() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)

        presenter.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        XCTAssertFalse(panel.isVisible)

        presenter.render(
            isPresented: false,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        XCTAssertTrue(panel.isVisible)
    }

    func test_renderReopensTheSamePanelAfterItWasDismissed() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let firstPanel = try XCTUnwrap(presenter.panel)

        presenter.render(
            isPresented: false,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        XCTAssertTrue(presenter.panel === firstPanel)
        XCTAssertTrue(firstPanel.isVisible)
    }

    private func extractedSettings(from view: PreferencesView) -> AppSettings? {
        extractValue(of: AppSettings.self, from: view)
    }

    private func extractValue<T>(of type: T.Type, from value: Any, depth: Int = 4) -> T? {
        if let typedValue = value as? T {
            return typedValue
        }

        guard depth > 0 else {
            return nil
        }

        for child in Mirror(reflecting: value).children {
            if let extractedValue = extractValue(of: type, from: child.value, depth: depth - 1) {
                return extractedValue
            }
        }

        return nil
    }
}
