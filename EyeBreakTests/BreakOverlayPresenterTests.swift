import XCTest

@testable import EyeBreak

@MainActor
final class BreakOverlayPresenterTests: XCTestCase {
    func test_renderShowsOverlayWhenPresentationBridgeIsActive() {
        let presenter = BreakOverlayPresenter()

        presenter.render(
            isPresented: true,
            remainingSeconds: 45,
            totalSeconds: 60,
            onSkip: {}
        )

        XCTAssertNotNil(presenter.panelForTesting)
    }

    func test_renderHidesOverlayWhenPresentationBridgeIsInactive() {
        let presenter = BreakOverlayPresenter()
        presenter.render(
            isPresented: true,
            remainingSeconds: 45,
            totalSeconds: 60,
            onSkip: {}
        )

        presenter.render(
            isPresented: false,
            remainingSeconds: 0,
            totalSeconds: 0,
            onSkip: {}
        )

        XCTAssertFalse(presenter.panelForTesting?.isVisible ?? true)
    }

    func test_showReusesHostingViewAndUpdatesRemainingSeconds() {
        let presenter = BreakOverlayPresenter()

        presenter.show(remainingSeconds: 20, totalSeconds: 20, onSkip: {})
        let firstPanel = presenter.panelForTesting
        let firstHostingView = presenter.hostingViewForTesting

        presenter.show(remainingSeconds: 19, totalSeconds: 20, onSkip: {})

        XCTAssertTrue(firstPanel === presenter.panelForTesting)
        XCTAssertTrue(firstHostingView === presenter.hostingViewForTesting)
        XCTAssertEqual(presenter.hostingViewForTesting?.rootView.remainingSeconds, 19)
        XCTAssertEqual(
            presenter.hostingViewForTesting?.rootView.progressValue ?? 0, 0.95, accuracy: 0.001)
    }

    func test_breakOverlayViewUsesRemainingTimeForProgressLine() {
        let view = BreakOverlayView(
            remainingSeconds: 45,
            totalSeconds: 60,
            onSkip: {}
        )

        XCTAssertEqual(view.progressValue, 0.75, accuracy: 0.001)
    }
}
