import XCTest

@testable import EyeBreak

@MainActor
final class ReminderWindowViewTests: XCTestCase {
    func test_routerOpensWhenReminderBecomesDesired() {
        var router = ReminderWindowRouter()

        let action = router.updateDesiredPresentation(true)

        XCTAssertEqual(action, ReminderWindowRouter.Action.open)
    }

    func test_routerDismissesWhenReminderIsNoLongerDesired() {
        var router = ReminderWindowRouter()
        _ = router.updateDesiredPresentation(true)
        _ = router.updateWindowVisibility(true)

        let action = router.updateDesiredPresentation(false)

        XCTAssertEqual(action, ReminderWindowRouter.Action.dismiss)
    }

    func test_routerReopensWhenUserClosesWindowWhileReminderIsStillDesired() {
        var router = ReminderWindowRouter()
        _ = router.updateDesiredPresentation(true)
        _ = router.updateWindowVisibility(true)

        let action = router.updateWindowVisibility(false)

        XCTAssertEqual(action, ReminderWindowRouter.Action.open)
    }

    func test_reminderWindowRendersIdleProgress() {
        let view = ReminderWindowView(
            breakType: .short,
            breakDuration: 20,
            idleDuration: 2,
            idleThreshold: 5,
            onStartNow: {},
            onSkip: {}
        )

        XCTAssertEqual(view.progressValue, 0.6, accuracy: 0.001)
    }

    func test_reminderPopupViewUsesIdleThresholdForProgressLine() {
        let view = ReminderPopupView(
            breakType: .short,
            breakDuration: 20,
            idleDuration: 2,
            idleThreshold: 5,
            onStartNow: {},
            onSkip: {}
        )

        XCTAssertEqual(view.progressValue, 0.6, accuracy: 0.001)
    }
}
