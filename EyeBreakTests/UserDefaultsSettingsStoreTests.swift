import XCTest
@testable import EyeBreak

final class UserDefaultsSettingsStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: UserDefaultsSettingsStore!
    let suiteName = "com.example.EyeBreak.UserDefaultsSettingsStoreTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = UserDefaultsSettingsStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_save_encodesAndStoresSettingsCorrectly() {
        var settings = AppSettings.default
        settings.activeInterval = 1234
        settings.launchAtLogin = true

        store.save(settings)

        let data = defaults.data(forKey: "AppSettings")
        XCTAssertNotNil(data, "Settings should be stored as Data")

        if let data = data {
            let decodedSettings = try? JSONDecoder().decode(AppSettings.self, from: data)
            XCTAssertEqual(decodedSettings, settings, "Saved settings should decode to the original value")
        }
    }

    func test_load_returnsNilWhenNoDataExists() {
        let loadedSettings = store.load()
        XCTAssertNil(loadedSettings)
    }

    func test_load_returnsSettingsWhenValidDataExists() {
        var settings = AppSettings.default
        settings.shortBreakDuration = 42

        let data = try! JSONEncoder().encode(settings)
        defaults.set(data, forKey: "AppSettings")

        let loadedSettings = store.load()
        XCTAssertEqual(loadedSettings, settings)
    }

    func test_load_returnsNilWhenDataIsInvalid() {
        let invalidData = Data([0x00, 0xFF, 0xAA])
        defaults.set(invalidData, forKey: "AppSettings")

        let loadedSettings = store.load()
        XCTAssertNil(loadedSettings)
    }
}
