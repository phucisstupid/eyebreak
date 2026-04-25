import XCTest

@testable import EyeBreak

final class BreakTypeTests: XCTestCase {


    func test_duration_returnsShortBreakDuration_forShortBreak() {
        let settings = AppSettings.default
        let breakType = BreakType.short

        let duration = breakType.duration(using: settings)

        XCTAssertEqual(duration, settings.shortBreakDuration)
    }

    func test_duration_returnsLongBreakDuration_forLongBreak() {
        var settings = AppSettings.default
        settings.longBreakDuration = 120
        let breakType = BreakType.long

        let duration = breakType.duration(using: settings)

        XCTAssertEqual(duration, settings.longBreakDuration)
    }

    func test_next_returnsShort_whenLongBreakFrequencyIsZero() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 0

        let nextType = BreakType.next(afterCompletedBreakCount: 5, using: settings)

        XCTAssertEqual(nextType, .short)
    }

    func test_next_returnsShort_whenCountPlusOneIsNotMultipleOfFrequency() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 3

        // Count 1 -> +1 is 2. 2 is not multiple of 3. -> short
        let nextType = BreakType.next(afterCompletedBreakCount: 1, using: settings)

        XCTAssertEqual(nextType, .short)
    }

    func test_next_returnsLong_whenCountPlusOneIsMultipleOfFrequency() {
        var settings = AppSettings.default
        settings.longBreakFrequency = 3

        // Count 2 -> +1 is 3. 3 is multiple of 3. -> long
        let nextType = BreakType.next(afterCompletedBreakCount: 2, using: settings)

        XCTAssertEqual(nextType, .long)
    func test_next_whenLongBreakFrequencyIsGreaterThanZero_andMultipleNotReached_returnsShort() {
        let settings = makeSettings(longBreakFrequency: 3)

        // At count 0, the next break is 1. (1 is not multiple of 3)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 0, using: settings), .short)

        // At count 1, the next break is 2. (2 is not multiple of 3)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 1, using: settings), .short)
    }

    func test_next_whenLongBreakFrequencyIsGreaterThanZero_andMultipleIsReached_returnsLong() {
        let settings = makeSettings(longBreakFrequency: 3)

        // At count 2, the next break is 3. (3 is multiple of 3)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 2, using: settings), .long)

        // At count 5, the next break is 6. (6 is multiple of 3)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 5, using: settings), .long)
    }

    func test_next_whenLongBreakFrequencyIsGreaterThanZero_andMultipleIsReachedAgain_returnsLong() {
        let settings = makeSettings(longBreakFrequency: 2)

        // Every 2nd break is long
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 0, using: settings), .short)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 1, using: settings), .long)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 2, using: settings), .short)
        XCTAssertEqual(BreakType.next(afterCompletedBreakCount: 3, using: settings), .long)
    }
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
