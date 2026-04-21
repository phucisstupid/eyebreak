import Foundation
@testable import EyeBreak

class DummyAppCoordinator: AppCoordinating {
    var settings: AppSettings

    init(settings: AppSettings = .default) {
        self.settings = settings
    }

    func start() {}
    func stop() {}
    func pauseReminders() {}
    func resumeReminders() {}
    func skipCurrentReminder() {}
    func postponeCurrentReminder() {}
    func skipCurrentBreak() {}
    func postponeCurrentBreak() {}
    func startBreakNow() {}
    func updateSettings(_ settings: AppSettings) {}
    func observeStateChanges(_ observer: @escaping (AppSnapshot, AppSettings) -> Void) -> AppStateObservationToken { return AppStateObservationToken() }
    func removeStateChangeObserver(_ token: AppStateObservationToken) {}
}

extension AppModel {
    static func makeForTests(
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) -> AppModel {
        makeForTests(coordinator: DummyAppCoordinator(), snapshot: snapshot, settings: settings)
    }
}
