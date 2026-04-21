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
    }
}
