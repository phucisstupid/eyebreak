import XCTest

@testable import EyeBreak

final class AppStateStoreTests: XCTestCase {
    func test_initialSnapshotStartsRunningWithShortNextBreak() {
        let store = AppStateStore(settings: .default)

        XCTAssertEqual(store.snapshot.phase, .running)
        XCTAssertEqual(store.snapshot.breakCount, 0)
        XCTAssertEqual(store.snapshot.nextBreakType, .short)
    }

    func test_initialSnapshotUsesBreakSelectionForCustomSettings() {
        let settings = AppSettings(
            activeInterval: 20 * 60,
            shortBreakDuration: 20,
            longBreakDuration: 60,
            longBreakFrequency: 1,
            idleThreshold: 5,
            launchAtLogin: false
        )

        let store = AppStateStore(settings: settings)

        XCTAssertEqual(store.snapshot.nextBreakType, .long)
    }
}
