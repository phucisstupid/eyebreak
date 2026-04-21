import XCTest
@testable import EyeBreak

final class ActivityMonitorTests: XCTestCase {
    private struct StubIdleTimeProvider: IdleTimeProviding {
        let time: TimeInterval
        func currentIdleTime() -> TimeInterval { time }
    }

    func test_currentIdleDuration_returnsPositiveIdleTime() {
        let monitor = ActivityMonitor(idleTimeProvider: StubIdleTimeProvider(time: 5.5))
        XCTAssertEqual(monitor.currentIdleDuration(), 5.5)
    }

    func test_currentIdleDuration_clampsNegativeIdleTimeToZero() {
        let monitor = ActivityMonitor(idleTimeProvider: StubIdleTimeProvider(time: -2.0))
        XCTAssertEqual(monitor.currentIdleDuration(), 0)
    }

    func test_currentIdleDuration_returnsZeroForZeroIdleTime() {
        let monitor = ActivityMonitor(idleTimeProvider: StubIdleTimeProvider(time: 0))
        XCTAssertEqual(monitor.currentIdleDuration(), 0)
    }
}
