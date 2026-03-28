import Foundation

final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private let key = "AppSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}
