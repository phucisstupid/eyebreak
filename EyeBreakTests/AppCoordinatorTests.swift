import XCTest

@testable import EyeBreak

final class AppCoordinatorTests: XCTestCase {
    func test_tickTransitionsFromWaitingForIdleToBreakWhenIdleThresholdIsMet() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 5)
        )

        coordinator.replaceSnapshotForTesting(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )
        coordinator.handleHeartbeat(delta: 1)

        XCTAssertEqual(coordinator.store.snapshot.phase, .breakInProgress)
        XCTAssertEqual(coordinator.store.snapshot.remainingBreakSeconds, 20)
    }

    func test_activeBreakHeartbeatReducesRemainingBreakSeconds() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 5)
        )

        coordinator.replaceSnapshotForTesting(
            AppSnapshot(
                phase: .breakInProgress,
                breakCount: 0,
                nextBreakType: .short,
                breakSessionState: BreakSessionState(
                    breakType: .short,
                    remainingDuration: 20,
                    startedAt: .init(timeIntervalSince1970: 0)
                ),
                schedulerState: .running(progress: 1_200),
                idleDuration: 5,
                postpone: nil
            )
        )

        coordinator.handleHeartbeat(delta: 1)

        XCTAssertEqual(coordinator.store.snapshot.phase, .breakInProgress)
        XCTAssertEqual(coordinator.store.snapshot.remainingBreakSeconds, 19)
    }

    func test_startBreakNowImmediatelyBeginsBreakWhileWaitingForIdle() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0),
            now: { Date(timeIntervalSince1970: 42) }
        )

        coordinator.replaceSnapshotForTesting(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )

        coordinator.startBreakNow()

        XCTAssertEqual(coordinator.store.snapshot.phase, .breakInProgress)
        XCTAssertEqual(
            coordinator.store.snapshot.breakSessionState?.startedAt, Date(timeIntervalSince1970: 42)
        )
        XCTAssertEqual(coordinator.store.snapshot.remainingBreakSeconds, 20)
    }

    func test_startBreakNowBeginsBreakFromRunningPhase() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0),
            now: { Date(timeIntervalSince1970: 84) }
        )

        coordinator.replaceSnapshotForTesting(
            AppSnapshot(
                phase: .running,
                breakCount: 1,
                nextBreakType: .short,
                breakSessionState: nil,
                schedulerState: .running(progress: 300),
                idleDuration: 0,
                postpone: ReminderPostpone(startedAt: .init(timeIntervalSince1970: 0), duration: 300)
            )
        )

        coordinator.startBreakNow()

        XCTAssertEqual(coordinator.store.snapshot.phase, .breakInProgress)
        XCTAssertEqual(coordinator.store.snapshot.breakSessionState?.startedAt, Date(timeIntervalSince1970: 84))
        XCTAssertEqual(coordinator.store.snapshot.schedulerState, .running(progress: 300))
        XCTAssertNil(coordinator.store.snapshot.postpone)
    }

    func test_postponeCurrentReminderClearsWaitingStateAndStartsFiveMinutePostpone() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0),
            now: { Date(timeIntervalSince1970: 100) }
        )

        coordinator.replaceSnapshotForTesting(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )

        coordinator.postponeCurrentReminder()

        XCTAssertEqual(coordinator.store.snapshot.phase, .running)
        XCTAssertEqual(coordinator.store.snapshot.schedulerState, .running(progress: 0))
        XCTAssertEqual(
            coordinator.store.snapshot.postpone,
            ReminderPostpone(startedAt: .init(timeIntervalSince1970: 100), duration: 300)
        )
    }

    func test_skipCurrentBreakEndsBreakWithoutPostponingReminder() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0)
        )

        coordinator.replaceSnapshotForTesting(
            AppSnapshot(
                phase: .breakInProgress,
                breakCount: 0,
                nextBreakType: .short,
                breakSessionState: BreakSessionState(
                    breakType: .short,
                    remainingDuration: 15,
                    startedAt: .init(timeIntervalSince1970: 0)
                ),
                schedulerState: .running(progress: 1_200),
                idleDuration: 5,
                postpone: nil
            )
        )

        coordinator.skipCurrentBreak()

        XCTAssertEqual(coordinator.store.snapshot.phase, .running)
        XCTAssertNil(coordinator.store.snapshot.breakSessionState)
        XCTAssertNil(coordinator.store.snapshot.postpone)
        XCTAssertEqual(coordinator.store.snapshot.schedulerState, .running(progress: 0))
    }

    func test_postponeCurrentBreakCreatesFiveMinutePostpone() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0),
            now: { Date(timeIntervalSince1970: 250) }
        )

        coordinator.replaceSnapshotForTesting(
            AppSnapshot(
                phase: .breakInProgress,
                breakCount: 0,
                nextBreakType: .short,
                breakSessionState: BreakSessionState(
                    breakType: .short,
                    remainingDuration: 15,
                    startedAt: .init(timeIntervalSince1970: 0)
                ),
                schedulerState: .running(progress: 1_200),
                idleDuration: 5,
                postpone: nil
            )
        )

        coordinator.postponeCurrentBreak()

        XCTAssertEqual(coordinator.store.snapshot.phase, .running)
        XCTAssertNil(coordinator.store.snapshot.breakSessionState)
        XCTAssertEqual(
            coordinator.store.snapshot.postpone,
            ReminderPostpone(startedAt: .init(timeIntervalSince1970: 250), duration: 300)
        )
    }

    func test_activePostponeDoesNotOverwritePausedPhase() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0),
            now: { Date(timeIntervalSince1970: 100) }
        )

        coordinator.replaceSnapshotForTesting(
            AppSnapshot(
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
        )

        coordinator.handleHeartbeat(delta: 1)

        XCTAssertEqual(coordinator.store.snapshot.phase, .paused)
        XCTAssertEqual(
            coordinator.store.snapshot.schedulerState, .paused(progress: 300, origin: .running))
    }
}

private final class InMemorySettingsStore: SettingsStore {
    private var settings: AppSettings?

    init(settings: AppSettings? = .default) {
        self.settings = settings
    }

    func load() -> AppSettings? {
        settings
    }

    func save(_ settings: AppSettings) {
        self.settings = settings
    }
}

private struct StubIdleTimeProvider: IdleTimeProviding {
    var idleTime: TimeInterval

    func currentIdleTime() -> TimeInterval {
        idleTime
    }
}

@MainActor
final class HeartbeatTests: XCTestCase {
    func test_reportsActualElapsedTimeWhenMainRunLoopIsDelayed() {
        let heartbeat = Heartbeat(interval: 0.01)
        let expectation = expectation(description: "second tick")
        var deltas: [TimeInterval] = []

        heartbeat.onTick = { delta in
            deltas.append(delta)

            if deltas.count == 1 {
                Thread.sleep(forTimeInterval: 0.05)
            }

            if deltas.count == 2 {
                expectation.fulfill()
            }
        }

        heartbeat.start()
        wait(for: [expectation], timeout: 1)
        heartbeat.stop()

        XCTAssertGreaterThan(deltas.count, 1)
        XCTAssertGreaterThan(deltas[1], 0.04)
    }
}
