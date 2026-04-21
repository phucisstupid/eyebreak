import Foundation
@testable import EyeBreak

private final class DummyAppCoordinator: AppCoordinating {
    var settings: AppSettings = .default
    var snapshot: AppSnapshot = .waitingForIdle(progress: 0, breakCount: 0, nextBreakType: .short)

    func start() {}
    func stop() {}
    func pauseReminders() {}
    func resumeReminders() {}
    func skipCurrentReminder() {}
    func postponeCurrentReminder(by duration: TimeInterval) {}
    func skipCurrentBreak() {}
    func postponeCurrentBreak(by duration: TimeInterval) {}
    func startBreak() {}
    func observeStateChanges(onChange: @escaping (AppSnapshot, AppSettings) -> Void) -> any AppStateObservationToken {
        DummyToken()
    }
}

private struct DummyToken: AppStateObservationToken {
    func cancel() {}
}

extension AppModel {
    static func makeForTests(
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) -> AppModel {
        makeForTests(
            coordinator: DummyAppCoordinator(),
            launchAtLoginController: LaunchAtLoginController(),
            snapshot: snapshot,
            settings: settings
        )
    }
}
