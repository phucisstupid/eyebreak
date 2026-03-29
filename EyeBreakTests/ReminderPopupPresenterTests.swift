import AppKit
import XCTest

@testable import EyeBreak

@MainActor
final class ReminderPopupPresenterTests: XCTestCase {
    func test_renderCreatesNonActivatingStatusBarPanel() throws {
        let presenter = ReminderPopupPresenter()

        presenter.render(
            isPresented: true,
            state: .init(
                breakType: .short,
                breakDuration: 20,
                idleDuration: 0,
                idleThreshold: 5
            ),
            onSkip: {},
            onPostpone: {}
        )

        let panel = try XCTUnwrap(presenter.panelForTesting)
        XCTAssertEqual(panel.styleMask.contains(NSWindow.StyleMask.nonactivatingPanel), true)
        XCTAssertEqual(panel.level, NSWindow.Level.statusBar)
    }

    func test_renderReusesExistingHostingViewInsteadOfRecreatingWindow() {
        let presenter = ReminderPopupPresenter()

        presenter.render(
            isPresented: true,
            state: .init(
                breakType: .short,
                breakDuration: 20,
                idleDuration: 0,
                idleThreshold: 5
            ),
            onSkip: {},
            onPostpone: {}
        )
        let firstPanel = presenter.panelForTesting
        let firstHostingView = presenter.hostingViewForTesting

        presenter.render(
            isPresented: true,
            state: .init(
                breakType: .long,
                breakDuration: 60,
                idleDuration: 3,
                idleThreshold: 5
            ),
            onSkip: {},
            onPostpone: {}
        )

        XCTAssertTrue(firstPanel === presenter.panelForTesting)
        XCTAssertTrue(firstHostingView === presenter.hostingViewForTesting)
        XCTAssertEqual(presenter.hostingViewForTesting?.rootView.breakType, BreakType.long)
        XCTAssertEqual(presenter.hostingViewForTesting?.rootView.breakDuration, 60)
        XCTAssertEqual(presenter.hostingViewForTesting?.rootView.idleDuration, 3)
        XCTAssertEqual(presenter.hostingViewForTesting?.rootView.idleThreshold, 5)
        XCTAssertEqual(
            presenter.hostingViewForTesting?.rootView.progressValue ?? 0,
            0.4,
            accuracy: 0.001
        )
    }

    func test_renderHidesExistingPanelWhenPresentationIsDisabled() {
        let presenter = ReminderPopupPresenter()

        presenter.render(
            isPresented: true,
            state: .init(
                breakType: .short,
                breakDuration: 20,
                idleDuration: 0,
                idleThreshold: 5
            ),
            onSkip: {},
            onPostpone: {}
        )

        presenter.render(
            isPresented: false,
            state: .init(
                breakType: .short,
                breakDuration: 0,
                idleDuration: 0,
                idleThreshold: 1
            ),
            onSkip: {},
            onPostpone: {}
        )

        XCTAssertFalse(presenter.panelForTesting?.isVisible ?? true)
    }
}
