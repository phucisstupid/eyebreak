import XCTest
@testable import EyeBreak

final class BreakTypeTests: XCTestCase {

    // MARK: - duration(using:)

    func test_duration_whenShortBreak_returnsShortBreakDuration() {
        let settings = AppSettings(
            activeInterval: 0,
            shortBreakDuration: 42,
            longBreakDuration: 99,
            longBreakFrequency: 0,
            idleThreshold: 0,
            launchAtLogin: false
        )
        let breakType = BreakType.short

        XCTAssertEqual(breakType.duration(using: settings), 42)
    }

    func test_duration_whenLongBreak_returnsLongBreakDuration() {
        let settings = AppSettings(
            activeInterval: 0,
            shortBreakDuration: 42,
            longBreakDuration: 99,
            longBreakFrequency: 0,
            idleThreshold: 0,
            launchAtLogin: false
        )
        let breakType = BreakType.long

        XCTAssertEqual(breakType.duration(using: settings), 99)
    }

    // MARK: - next(afterCompletedBreakCount:using:)

    func test_next_whenLongBreakFrequencyIsZero_alwaysReturnsShort() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 0

        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 0, using: settings), .short)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 1, using: settings), .short)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 5, using: settings), .short)
    }

    func test_next_whenLongBreakFrequencyIsNegative_alwaysReturnsShort() {
        var settings = AppSettings.default
        settings.longBreakFrequency = -1

        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 0, using: settings), .short)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 2, using: settings), .short)
    }

    func test_next_returnsLongBreak_whenCompletedCountPlusOneIsMultipleOfFrequency() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 3

        // Count: 0 -> next break is 1st break -> short
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 0, using: settings), .short)

        // Count: 1 -> next break is 2nd break -> short
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 1, using: settings), .short)

        // Count: 2 -> next break is 3rd break -> long
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 2, using: settings), .long)

        // Count: 3 -> next break is 4th break -> short
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 3, using: settings), .short)

        // Count: 4 -> next break is 5th break -> short
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 4, using: settings), .short)

        // Count: 5 -> next break is 6th break -> long
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 5, using: settings), .long)
    }
}
