import XCTest

@testable import EyeBreak

final class BreakSchedulerTests: XCTestCase {
    func test_reachesWaitingForIdleAfterConfiguredActiveSeconds() {
        let scheduler = BreakScheduler(settings: .default)

        let result = scheduler.reduce(
            state: .running(progress: 1_199),
            event: .tick(activeDelta: 1, idleDuration: 0)
        )

        XCTAssertEqual(result.state, .waitingForIdle(progress: 1_200))
        XCTAssertEqual(result.commands, [.showReminder])
    }

    func test_idleTimeDoesNotAdvanceActiveProgress() {
        let scheduler = BreakScheduler(settings: .default)

        let result = scheduler.reduce(
            state: .running(progress: 300),
            event: .tick(activeDelta: 5, idleDuration: 5)
        )

        XCTAssertEqual(result.state, .running(progress: 300))
    }

    func test_pausePreventsFurtherProgress() {
        let scheduler = BreakScheduler(settings: .default)
        let paused = scheduler.reduce(state: .running(progress: 600), event: .pause).state
        let result = scheduler.reduce(state: paused, event: .tick(activeDelta: 5, idleDuration: 0))

        XCTAssertEqual(result.state, .paused(progress: 600, origin: .running))
    }

    func test_pauseAlsoWorksWhileWaitingForIdle() {
        let scheduler = BreakScheduler(settings: .default)

        let result = scheduler.reduce(
            state: .waitingForIdle(progress: 1_200),
            event: .pause
        )

        XCTAssertEqual(result.state, .paused(progress: 1_200, origin: .waitingForIdle))
    }

    func test_resumeRestoresWaitingForIdleAfterPausingReminder() {
        let scheduler = BreakScheduler(settings: .default)
        let paused = scheduler.reduce(
            state: .waitingForIdle(progress: 1_200),
            event: .pause
        ).state

        let result = scheduler.reduce(state: paused, event: .resume)

        XCTAssertEqual(result.state, .waitingForIdle(progress: 1_200))
        XCTAssertEqual(result.commands, [])
    }

    func test_skipReminderResetsProgressToZero() {
        let scheduler = BreakScheduler(settings: .default)
        let result = scheduler.reduce(
            state: .waitingForIdle(progress: 1_200),
            event: .skipReminder
        )

        XCTAssertEqual(result.state, .running(progress: 0))
        XCTAssertEqual(result.commands, [.hideReminder])
    }

    func test_sleepAndWakePreserveProgressWithoutCommands() {
        let scheduler = BreakScheduler(settings: .default)

        let sleepResult = scheduler.reduce(state: .running(progress: 540), event: .sleep)
        XCTAssertEqual(sleepResult.state, .running(progress: 540))
        XCTAssertEqual(sleepResult.commands, [])

        let wakeResult = scheduler.reduce(state: sleepResult.state, event: .wake)
        XCTAssertEqual(wakeResult.state, .running(progress: 540))
        XCTAssertEqual(wakeResult.commands, [])
    }
}
