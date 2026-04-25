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
