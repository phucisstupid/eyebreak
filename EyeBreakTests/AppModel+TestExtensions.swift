import Foundation
@testable import EyeBreak

extension AppModel {
    static func makeForTests(
        coordinator: any AppCoordinating = MockAppCoordinator(),
        launchAtLoginController: any LaunchAtLoginControlling = MockLaunchAtLoginController(),
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) -> AppModel {
        AppModel(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController,
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

    var snapshot: AppSnapshot { return .running(progress: 0, breakCount: 0, nextBreakType: .short) }
    var settings: AppSettings { return .default }
}

final class MockLaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled = false
}
