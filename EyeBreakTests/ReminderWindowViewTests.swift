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
            onSkip: {},
            onPostpone: {}
        )

        XCTAssertEqual(view.progressValue, 0.6, accuracy: 0.001)
    }

    func test_reminderPopupViewUsesIdleThresholdForProgressLine() {
        let view = ReminderPopupView(
            breakType: .short,
            breakDuration: 20,
            idleDuration: 2,
            idleThreshold: 5,
            onSkip: {},
            onPostpone: {}
        )

        XCTAssertEqual(view.progressValue, 0.6, accuracy: 0.001)
    }

    func test_reminderPopupViewProgressValueClampsWithinBounds() {
        XCTAssertEqual(
            ReminderPopupView.progressValue(idleDuration: -1, idleThreshold: 5),
            1,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ReminderPopupView.progressValue(idleDuration: 8, idleThreshold: 5),
            0,
            accuracy: 0.001
        )
    }
}
