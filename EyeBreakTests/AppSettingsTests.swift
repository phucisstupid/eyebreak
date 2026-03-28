import XCTest

@testable import EyeBreak

final class AppSettingsTests: XCTestCase {
    func test_defaultsMatchSpec() {
        let settings = AppSettings.default

        XCTAssertEqual(settings.activeInterval, 20 * 60)
        XCTAssertEqual(settings.shortBreakDuration, 20)
        XCTAssertEqual(settings.longBreakDuration, 60)
        XCTAssertEqual(settings.longBreakFrequency, 3)
        XCTAssertEqual(settings.idleThreshold, 5)
        XCTAssertEqual(settings.launchAtLogin, false)
    }
}
