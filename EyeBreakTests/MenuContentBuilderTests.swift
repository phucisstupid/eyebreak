import XCTest

@testable import EyeBreak

final class MenuContentBuilderTests: XCTestCase {
    func test_runningSnapshotShowsSecondBySecondCountdown() {
        let snapshot = AppSnapshot(
            phase: .running,
            breakCount: 0,
            nextBreakType: .short,
            breakSessionState: nil,
            schedulerState: .running(progress: 1),
            idleDuration: 0,
            postpone: nil
        )

        let content = MenuContentBuilder().build(from: snapshot, settings: .default)

        XCTAssertEqual(content.timeUntilNextReminderLine, "Time until next reminder: 19:59")
    }

    func test_runningSnapshotShowsRequiredMenuInformationRows() {
        let snapshot = AppSnapshot(
            phase: .running,
            breakCount: 1,
            nextBreakType: .short,
            breakSessionState: nil,
            schedulerState: .running(progress: 300),
            idleDuration: 0,
            postpone: nil
        )

        let content = MenuContentBuilder().build(from: snapshot, settings: .default)

        XCTAssertEqual(content.statusLine, "Tracking active time")
        XCTAssertEqual(content.timeUntilNextReminderLine, "Time until next reminder: 15:00")
        XCTAssertEqual(content.waitingForIdleLine, "Waiting for idle: No")
        XCTAssertEqual(content.breakCountLine, "Current break count: 1")
        XCTAssertEqual(content.nextBreakTypeLine, "Next break type: Short")
        XCTAssertTrue(content.canStartBreakNow)
    }

    func test_waitingForIdleSnapshotShowsPendingReminderRows() {
        let snapshot = AppSnapshot.waitingForIdle(
            progress: 1_200,
            breakCount: 2,
            nextBreakType: .long
        )

        let content = MenuContentBuilder().build(from: snapshot, settings: .default)

        XCTAssertEqual(content.statusLine, "Reminder ready")
        XCTAssertEqual(content.timeUntilNextReminderLine, "Time until next reminder: 00:00")
        XCTAssertEqual(content.waitingForIdleLine, "Waiting for idle: Yes")
        XCTAssertEqual(content.breakCountLine, "Current break count: 2")
        XCTAssertEqual(content.nextBreakTypeLine, "Next break type: Long")
    }

    func test_pausedSnapshotWithPostponeStillShowsPausedStatus() {
        let snapshot = AppSnapshot(
            phase: .paused,
            breakCount: 1,
            nextBreakType: .short,
            breakSessionState: nil,
            schedulerState: .paused(progress: 300, origin: .running),
            idleDuration: 0,
            postpone: ReminderPostpone(
                startedAt: Date(timeIntervalSince1970: 0),
                duration: 300
            )
        )

        let content = MenuContentBuilder().build(from: snapshot, settings: .default)

        XCTAssertEqual(content.statusLine, "Reminders paused")
        XCTAssertEqual(content.timeUntilNextReminderLine, "Time until next reminder: 15:00")
        XCTAssertEqual(content.waitingForIdleLine, "Waiting for idle: No")
        XCTAssertTrue(content.canResume)
        XCTAssertFalse(content.canPause)
        XCTAssertFalse(content.canStartBreakNow)
    }
}
