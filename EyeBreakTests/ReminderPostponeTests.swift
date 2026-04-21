import XCTest

@testable import EyeBreak

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

        XCTAssertEqual(postpone.endsAt, startedAt.addingTimeInterval(300))
    }
}
