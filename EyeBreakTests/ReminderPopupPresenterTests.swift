import AppKit
import XCTest
@testable import EyeBreak

@MainActor
final class ReminderPopupPresenterTests: XCTestCase {
    func test_showCreatesNonActivatingPanelOnMainDisplay() {
        let presenter = ReminderPopupPresenter()

        presenter.render(
            isPresented: true,
            breakType: .short,
            breakDuration: 20,
            idleDuration: 0,
            idleThreshold: 5,
            onStartNow: {},
            onSkip: {}
        )

        let panel = try XCTUnwrap(presenter.panelForTesting)
        XCTAssertEqual(panel.styleMask.contains(.nonactivatingPanel), true)
        XCTAssertEqual(panel.level, .statusBar)
    }

    func test_renderReusesExistingHostingViewInsteadOfRecreatingWindow() {
        let presenter = ReminderPopupPresenter()

        presenter.render(
            isPresented: true,
            breakType: .short,
            breakDuration: 20,
            idleDuration: 0,
            idleThreshold: 5,
            onStartNow: {},
            onSkip: {}
        )
        let firstPanel = presenter.panelForTesting
        let firstHostingView = presenter.hostingViewForTesting

        presenter.render(
            isPresented: true,
            breakType: .long,
            breakDuration: 60,
            idleDuration: 3,
            idleThreshold: 5,
            onStartNow: {},
            onSkip: {}
        )

        XCTAssertTrue(firstPanel === presenter.panelForTesting)
        XCTAssertTrue(firstHostingView === presenter.hostingViewForTesting)
    }
}
