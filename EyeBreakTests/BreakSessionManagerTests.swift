import XCTest

@testable import EyeBreak

final class BreakSessionManagerTests: XCTestCase {
    func test_everyThirdCompletedBreakUsesLongDuration() {
        let manager = BreakSessionManager(settings: .default)

        let third = manager.startBreak(
            completedBreakCount: 2,
            startedAt: .init(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(third.breakType, .long)
        XCTAssertEqual(third.remainingDuration, 60)
    }

    func test_partialTickKeepsSessionActiveWithReducedRemainingDuration() {
        let manager = BreakSessionManager(settings: .default)
        let session = manager.startBreak(
            completedBreakCount: 0,
            startedAt: .init(timeIntervalSince1970: 0)
        )

        let result = manager.tick(session: session, delta: 5)

        XCTAssertEqual(result.completedBreakCountDelta, 0)
        XCTAssertEqual(result.completedBreakType, nil)
        XCTAssertEqual(result.completedAt, nil)
        XCTAssertEqual(
            result.nextSession,
            .init(
                breakType: .short,
                remainingDuration: 15,
                startedAt: .init(timeIntervalSince1970: 0)
            ))
    }

    func test_completedBreakIncrementsCountAndClearsSession() {
        let manager = BreakSessionManager(settings: .default)
        let session = manager.startBreak(
            completedBreakCount: 0,
            startedAt: .init(timeIntervalSince1970: 0)
        )

        let result = manager.tick(session: session, delta: 20)

        XCTAssertEqual(result.completedBreakCountDelta, 1)
        XCTAssertEqual(result.completedBreakType, .short)
        XCTAssertEqual(result.completedAt, .init(timeIntervalSince1970: 20))
        XCTAssertNil(result.nextSession)
    }

    func test_skipBreakCreatesFiveMinutePostponeWithoutIncrementingCount() {
        let manager = BreakSessionManager(settings: .default)
        let session = manager.startBreak(
            completedBreakCount: 0,
            startedAt: .init(timeIntervalSince1970: 0)
        )

        let result = manager.skip(session: session, now: .init(timeIntervalSince1970: 100))

        XCTAssertEqual(result.completedBreakCountDelta, 0)
        XCTAssertEqual(
            result.postpone,
            .init(
                startedAt: .init(timeIntervalSince1970: 100),
                duration: 300
            ))
        XCTAssertEqual(result.postpone?.endsAt, .init(timeIntervalSince1970: 400))
    }
}
