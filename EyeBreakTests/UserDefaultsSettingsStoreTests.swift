import XCTest
@testable import EyeBreak

final class UserDefaultsSettingsStoreTests: XCTestCase {
    var userDefaults: UserDefaults!
    var sut: UserDefaultsSettingsStore!

    override func setUp() {
        super.setUp()
        // Create a custom suite for testing to avoid polluting standard defaults
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = UserDefaultsSettingsStore(defaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = nil
        userDefaults = nil
        super.tearDown()
    }

    func test_load_whenNoDataExists_returnsNil() {
        let settings = sut.load()
        XCTAssertNil(settings)
    }

    func test_saveAndLoad_whenDataExists_returnsSavedSettings() {
        var settings = AppSettings.default
        settings.activeInterval = 999

        sut.save(settings)
        let loadedSettings = sut.load()

        XCTAssertEqual(loadedSettings, settings)
    }

    func test_load_whenInvalidDataExists_returnsNil() {
        let invalidData = "Not a valid JSON".data(using: .utf8)!
        userDefaults.set(invalidData, forKey: "AppSettings")

        let settings = sut.load()

        XCTAssertNil(settings)
    }
}
