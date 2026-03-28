import XCTest

@testable import EyeBreak

@MainActor
final class MenuBarContentViewTests: XCTestCase {
    func test_menuContentReflectsWaitingForIdleState() {
        let settings = AppSettings.default
        let snapshot = AppSnapshot.waitingForIdle(
            progress: settings.activeInterval,
            breakCount: 2,
            nextBreakType: .long
        )
        let model = AppModel.makeForTests(snapshot: snapshot, settings: settings)
        let view = MenuBarContentView(
            model: model,
            quit: {}
        )

        XCTAssertEqual(view.menuContent.statusLine, "Reminder ready")
        XCTAssertEqual(
            view.menuContent.timeUntilNextReminderLine, "Time until next reminder: 00:00")
        XCTAssertEqual(view.menuContent.waitingForIdleLine, "Waiting for idle: Yes")
        XCTAssertEqual(view.menuContent.breakCountLine, "Current break count: 2")
        XCTAssertEqual(view.menuContent.nextBreakTypeLine, "Next break type: Long")
        XCTAssertTrue(view.menuContent.canPause)
        XCTAssertFalse(view.menuContent.canResume)
        XCTAssertTrue(view.menuContent.canSkipReminder)
    }

    func test_quitCommandInvokesClosure() {
        let model = AppModel.makeForTests()
        var quitRequested = false
        let view = MenuBarContentView(
            model: model,
            quit: { quitRequested = true }
        )
        view.quit()
        XCTAssertTrue(quitRequested)
    }
}
