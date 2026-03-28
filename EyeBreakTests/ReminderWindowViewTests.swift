import XCTest

@testable import EyeBreak

@MainActor
final class ReminderWindowViewTests: XCTestCase {
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
