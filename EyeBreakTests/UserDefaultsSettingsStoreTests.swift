import XCTest

@testable import EyeBreak

final class UserDefaultsSettingsStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsSettingsStore!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "UserDefaultsSettingsStoreTests")
        userDefaults.removePersistentDomain(forName: "UserDefaultsSettingsStoreTests")
        store = UserDefaultsSettingsStore(defaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "UserDefaultsSettingsStoreTests")
        userDefaults = nil
        store = nil
        super.tearDown()
    }

    func test_save_encodesAndStoresSettingsCorrectly() throws {
        // Arrange
        let settings = AppSettings(
            activeInterval: 1200,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            longBreakFrequency: 4,
            idleThreshold: 60,
            launchAtLogin: true
        )

        // Act
        store.save(settings)

        // Assert
        let data = userDefaults.data(forKey: "AppSettings")
        XCTAssertNotNil(data, "Saved data should not be nil")

        let decodedSettings = try JSONDecoder().decode(AppSettings.self, from: data!)
        XCTAssertEqual(decodedSettings, settings, "The decoded settings should match the saved settings")
    }

    func test_load_returnsNilWhenNoData() {
        let loadedSettings = store.load()
        XCTAssertNil(loadedSettings, "Loading without saved data should return nil")
    }

    func test_load_returnsSavedSettings() {
        // Arrange
        let settings = AppSettings(
            activeInterval: 1200,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            longBreakFrequency: 4,
            idleThreshold: 60,
            launchAtLogin: true
        )
        store.save(settings)

        // Act
        let loadedSettings = store.load()

        // Assert
        XCTAssertEqual(loadedSettings, settings, "The loaded settings should match the saved settings")
    }
}
