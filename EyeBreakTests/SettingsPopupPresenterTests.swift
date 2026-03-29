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
