import XCTest
@testable import EyeBreak

final class AppSnapshotTests: XCTestCase {
    func test_initial_createsSnapshotWithCorrectProperties() {
        // Arrange
        let settings = AppSettings.default
        let expectedBreakCount = 0
        let expectedNextBreakType = BreakType.next(afterCompletedBreakCount: expectedBreakCount, using: settings)

        // Act
        let snapshot = AppSnapshot.initial(settings: settings)

        // Assert
        XCTAssertEqual(snapshot.phase, .running)
        XCTAssertEqual(snapshot.breakCount, expectedBreakCount)
        XCTAssertEqual(snapshot.nextBreakType, expectedNextBreakType)
        XCTAssertNil(snapshot.breakSessionState)
        XCTAssertEqual(snapshot.schedulerState, .running(progress: 0))
        XCTAssertEqual(snapshot.idleDuration, 0)
        XCTAssertNil(snapshot.postpone)
    }

    func test_waitingForIdle_createsSnapshotWithCorrectProperties() {
        // Arrange
        let progress: TimeInterval = 120
        let breakCount = 5
        let nextBreakType = BreakType.long

        // Act
        let snapshot = AppSnapshot.waitingForIdle(
            progress: progress,
            breakCount: breakCount,
            nextBreakType: nextBreakType
        )

        // Assert
        XCTAssertEqual(snapshot.phase, .waitingForIdle)
        XCTAssertEqual(snapshot.breakCount, breakCount)
        XCTAssertEqual(snapshot.nextBreakType, nextBreakType)
        XCTAssertNil(snapshot.breakSessionState)
        XCTAssertEqual(snapshot.schedulerState, .waitingForIdle(progress: progress))
        XCTAssertEqual(snapshot.idleDuration, 0)
        XCTAssertNil(snapshot.postpone)
    }

    func test_remainingBreakSeconds_withNoSession_returnsZero() {
        // Arrange
        var snapshot = AppSnapshot.initial(settings: .default)
        snapshot.breakSessionState = nil

        // Act & Assert
        XCTAssertEqual(snapshot.remainingBreakSeconds, 0)
    }

    func test_remainingBreakSeconds_withSession_returnsCeilRemainingDuration() {
        // Arrange
        var snapshot = AppSnapshot.initial(settings: .default)

        let testCases: [(duration: TimeInterval, expected: Int)] = [
            (0.0, 0),
            (0.1, 1),
            (1.0, 1),
            (1.5, 2),
            (5.9, 6)
        ]

        for testCase in testCases {
            snapshot.breakSessionState = BreakSessionState(
                breakType: .short,
                remainingDuration: testCase.duration,
                startedAt: Date()
            )

            // Act & Assert
            XCTAssertEqual(
                snapshot.remainingBreakSeconds,
                testCase.expected,
                "Failed for duration \(testCase.duration)"
            )
        }
    }
}
