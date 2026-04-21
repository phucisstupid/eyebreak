import XCTest

@testable import EyeBreak

final class BreakTypeTests: XCTestCase {

    // MARK: - Helper to get AppSettings
    private func makeSettings(longBreakFrequency: Int) -> AppSettings {
        var settings = AppSettings.default
        settings.longBreakFrequency = longBreakFrequency
        return settings
    }

    // MARK: - Tests

    func test_next_whenLongBreakFrequencyIsZero_returnsShort() {
        let settings = makeSettings(longBreakFrequency: 0)

        let nextBreak = BreakType.next(afterCompletedBreakCount: 1, using: settings)

        XCTAssertEqual(nextBreak, .short)
    }

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
}
