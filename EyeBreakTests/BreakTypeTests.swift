import XCTest
@testable import EyeBreak

final class BreakTypeTests: XCTestCase {
    func test_next_withLongFrequencyZero_returnsShort() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 0

        let nextBreak = BreakType.next(afterCompletedBreakCount: 5, using: settings)

        XCTAssertEqual(nextBreak, .short)
    }

    func test_next_whenMultipleNotReached_returnsShort() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 3

        let nextBreak = BreakType.next(afterCompletedBreakCount: 1, using: settings)

        XCTAssertEqual(nextBreak, .short)
    }

    func test_next_whenMultipleReached_returnsLong() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 3

        let nextBreak = BreakType.next(afterCompletedBreakCount: 2, using: settings)

        XCTAssertEqual(nextBreak, .long)
    }

    func test_duration_returnsCorrectValue() {
        var settings = AppSettings.default
        settings.shortBreakDuration = 25
        settings.longBreakDuration = 75

        XCTAssertEqual(BreakType.short.duration(using: settings), 25)
        XCTAssertEqual(BreakType.long.duration(using: settings), 75)
    }
}
