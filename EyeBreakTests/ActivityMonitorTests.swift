import XCTest
@testable import EyeBreak

final class ActivityMonitorTests: XCTestCase {
    private struct StubIdleTimeProvider: IdleTimeProviding {
        let stubbedIdleTime: TimeInterval

        func currentIdleTime() -> TimeInterval {
            stubbedIdleTime
        }
    }

    func test_currentIdleDuration_whenIdleTimeIsPositive_returnsIdleTime() {
        // Arrange
        let stubProvider = StubIdleTimeProvider(stubbedIdleTime: 5.0)
        let monitor = ActivityMonitor(idleTimeProvider: stubProvider)

        // Act
        let duration = monitor.currentIdleDuration()

        // Assert
        XCTAssertEqual(duration, 5.0)
    }

    func test_currentIdleDuration_whenIdleTimeIsZero_returnsZero() {
        // Arrange
        let stubProvider = StubIdleTimeProvider(stubbedIdleTime: 0.0)
        let monitor = ActivityMonitor(idleTimeProvider: stubProvider)

        // Act
        let duration = monitor.currentIdleDuration()

        // Assert
        XCTAssertEqual(duration, 0.0)
    }

    func test_currentIdleDuration_whenIdleTimeIsNegative_returnsZero() {
        // Arrange
        let stubProvider = StubIdleTimeProvider(stubbedIdleTime: -2.5)
        let monitor = ActivityMonitor(idleTimeProvider: stubProvider)

        // Act
        let duration = monitor.currentIdleDuration()

        // Assert
        XCTAssertEqual(duration, 0.0)
    }
}
