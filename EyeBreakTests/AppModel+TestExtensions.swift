import Foundation
@testable import EyeBreak

extension AppModel {
    static func makeForTests(
        coordinator: any AppCoordinating = MockAppCoordinator(),
        launchAtLoginController: any LaunchAtLoginControlling = MockLaunchAtLoginController(),
        coordinator: any AppCoordinating,
        launchAtLoginController: any LaunchAtLoginControlling = LaunchAtLoginController(),
        coordinator: any AppCoordinating,
        launchAtLoginController: any LaunchAtLoginControlling = LaunchAtLoginController(),
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) -> AppModel {
        AppModel(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController,
@testable import EyeBreak

private final class DummyAppCoordinator: AppCoordinating {
    var settings: AppSettings = .default
    var snapshot: AppSnapshot = .waitingForIdle(progress: 0, breakCount: 0, nextBreakType: .short)
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
            snapshot: snapshot,
            settings: settings
        )
    }
}

final class MockAppCoordinator: AppCoordinating {
    func start() {}
    func stop() {}
    func showSettings() {}
    func showReminderWindow(breakType: BreakType) {}
    func showBreakOverlay(breakType: BreakType, onDismiss: @escaping () -> Void) {}
    func showPostponeReminderWindow(breakType: BreakType) {}
    func hideReminderWindow() {}
    func hidePostponeReminderWindow() {}
    func quit() {}
    func observeStateChanges(_ observer: @escaping (AppSnapshot, AppSettings) -> Void) -> AppStateObservationToken { return UUID() }
    func removeStateChangeObserver(_ token: AppStateObservationToken) {}
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
