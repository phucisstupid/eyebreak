import XCTest
@testable import EyeBreak

final class HeartbeatTests: XCTestCase {

    final class MockTimer: HeartbeatTimer {
        var isInvalidated = false
        func invalidate() {
            isInvalidated = true
        }
    }

    func test_start_callsOnTickWithDelta() {
        var uptime: TimeInterval = 100
        var timerBlock: (() -> Void)?
        let mockTimer = MockTimer()

        let heartbeat = Heartbeat(
            interval: 1,
            uptimeProvider: { uptime },
            scheduleTimer: { _, block in
                timerBlock = block
                return mockTimer
            }
        )

        var ticks: [TimeInterval] = []
        heartbeat.onTick = { delta in
            ticks.append(delta)
        }

        heartbeat.start()

        // Advance time by 1.5 seconds
        uptime = 101.5
        timerBlock?()

        // Advance time by 1.0 second
        uptime = 102.5
        timerBlock?()

        XCTAssertEqual(ticks.count, 2)
        XCTAssertEqual(ticks[0], 1.5)
        XCTAssertEqual(ticks[1], 1.0)
    }

    func test_start_multipleTimes_ignoresSubsequentCalls() {
        var scheduleCount = 0

        let heartbeat = Heartbeat(
            interval: 1,
            uptimeProvider: { 100 },
            scheduleTimer: { _, _ in
                scheduleCount += 1
                return MockTimer()
            }
        )

        heartbeat.start()
        heartbeat.start()
        heartbeat.start()

        XCTAssertEqual(scheduleCount, 1)
    }

    func test_stop_invalidatesTimer() {
        let mockTimer = MockTimer()
        let heartbeat = Heartbeat(
            interval: 1,
            uptimeProvider: { 100 },
            scheduleTimer: { _, _ in mockTimer }
        )

        heartbeat.start()
        XCTAssertFalse(mockTimer.isInvalidated)

        heartbeat.stop()
        XCTAssertTrue(mockTimer.isInvalidated)

        // Can start again after stopping
        var scheduleCount = 0
        let heartbeat2 = Heartbeat(
            interval: 1,
            uptimeProvider: { 100 },
            scheduleTimer: { _, _ in
                scheduleCount += 1
                return MockTimer()
            }
        )

        heartbeat2.start()
        heartbeat2.stop()
        heartbeat2.start()
        XCTAssertEqual(scheduleCount, 2)
    }

    func test_tick_negativeDeltaIsClampedToZero() {
        var uptime: TimeInterval = 100
        var timerBlock: (() -> Void)?

        let heartbeat = Heartbeat(
            interval: 1,
            uptimeProvider: { uptime },
            scheduleTimer: { _, block in
                timerBlock = block
                return MockTimer()
            }
        )

        var lastTickDelta: TimeInterval?
        heartbeat.onTick = { delta in
            lastTickDelta = delta
        }

        heartbeat.start()

        // Simulate time going backwards (e.g. system sleep/wake anomaly)
        uptime = 90
        timerBlock?()

        XCTAssertEqual(lastTickDelta, 0)
    }
}
