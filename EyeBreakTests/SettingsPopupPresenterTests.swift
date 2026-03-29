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
        XCTAssertNotEqual(panel.frame.origin, .zero)
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

    func test_renderRecreatesPreferencesViewWithUpdatedLaunchAtLoginValue() throws {
        let presenter = SettingsPopupPresenter()
        let initialSettings = AppSettings.default
        var updatedSettings = AppSettings.default
        updatedSettings.launchAtLogin = true

        presenter.render(
            isPresented: true,
            settings: initialSettings,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let panel = try XCTUnwrap(presenter.panel)
        let firstHostingView = try XCTUnwrap(panel.contentView as? NSHostingView<PreferencesView>)
        XCTAssertFalse(firstHostingView.rootView.launchAtLoginBinding.wrappedValue)

        presenter.render(
            isPresented: true,
            settings: updatedSettings,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let secondHostingView = try XCTUnwrap(panel.contentView as? NSHostingView<PreferencesView>)
        XCTAssertTrue(secondHostingView.rootView.launchAtLoginBinding.wrappedValue)
        XCTAssertFalse(firstHostingView.rootView.launchAtLoginBinding.wrappedValue)
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

    func test_defaultOriginPlacesPopupInsideTopTrailingVisibleFrame() {
        let visibleFrame = CGRect(x: 100, y: 200, width: 1200, height: 900)
        let size = PreferencesView.nativeWindowSize

        let origin = SettingsPopupPresenter.defaultOrigin(for: size, in: visibleFrame)

        XCTAssertEqual(origin.x, visibleFrame.maxX - size.width - 16, accuracy: 0.5)
        XCTAssertEqual(origin.y, visibleFrame.maxY - size.height - 12, accuracy: 0.5)
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

    func test_presentReopensAfterResignKeyWithoutNeedingAPresentationStateReset() throws {
        let presenter = SettingsPopupPresenter()

        presenter.render(
            isPresented: true,
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )
        let panel = try XCTUnwrap(presenter.panel)

        presenter.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification, object: panel))

        presenter.present(
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
}
