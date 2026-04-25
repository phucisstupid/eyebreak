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

    func test_postponeBreakCreatesFiveMinutePostponeWithoutIncrementingCount() {
        let manager = BreakSessionManager(settings: .default)
        let session = manager.startBreak(
            completedBreakCount: 0,
            startedAt: .init(timeIntervalSince1970: 0)
        )

        let result = manager.postpone(session: session, now: .init(timeIntervalSince1970: 100))

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

final class ReminderPostponeTests: XCTestCase {
    func test_endsAt_returnsStartedAtPlusDuration() {
        let startedAt = Date(timeIntervalSince1970: 1000)
        let duration: TimeInterval = 300
        let postpone = ReminderPostpone(startedAt: startedAt, duration: duration)

        let expectedEndsAt = Date(timeIntervalSince1970: 1300)
        XCTAssertEqual(postpone.endsAt, expectedEndsAt)
    }

    func test_standard_createsPostponeWithStandardDuration() {
        let startedAt = Date(timeIntervalSince1970: 2000)
        let postpone = ReminderPostpone.standard(from: startedAt)

        let expected = ReminderPostpone(startedAt: startedAt, duration: ReminderPostpone.standardDuration)
        XCTAssertEqual(postpone, expected)
    }

    func test_standardDuration_isFiveMinutes() {
        XCTAssertEqual(ReminderPostpone.standardDuration, 300)
    }

    func test_standard_endsAt_isFiveMinutesAfterStartedAt() {
        let startedAt = Date(timeIntervalSince1970: 2000)
        let postpone = ReminderPostpone.standard(from: startedAt)

        XCTAssertEqual(postpone.endsAt, startedAt.addingTimeInterval(ReminderPostpone.standardDuration))
    }
}
