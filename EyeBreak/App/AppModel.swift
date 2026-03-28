import Combine
import Foundation

@MainActor
protocol LaunchAtLoginControlling {
    @discardableResult
    func setEnabled(_ enabled: Bool) -> String?
}

extension LaunchAtLoginController: LaunchAtLoginControlling {}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot: AppSnapshot
    @Published private(set) var settings: AppSettings
    @Published private(set) var isReminderWindowPresented: Bool

    private let coordinator: any AppCoordinating
    private let launchAtLoginController: any LaunchAtLoginControlling
    private var stateChangeObservation: StateChangeObservation?
    private var hasStartedCoordinator = false

    var reminderWindowState: ReminderWindowState? {
        guard snapshot.phase == .waitingForIdle else {
            return nil
        }

        return ReminderWindowState(
            breakType: snapshot.nextBreakType,
            breakDuration: snapshot.nextBreakType.duration(using: settings),
            idleDuration: snapshot.idleDuration,
            idleThreshold: settings.idleThreshold
        )
    }

    var breakOverlayState: BreakOverlayState? {
        guard snapshot.phase == .breakInProgress else {
            return nil
        }

        let totalSeconds =
            snapshot.breakSessionState.map {
                Int(ceil($0.breakType.duration(using: settings)))
            } ?? snapshot.remainingBreakSeconds

        return BreakOverlayState(
            remainingSeconds: snapshot.remainingBreakSeconds,
            totalSeconds: totalSeconds
        )
    }

    init(
        coordinator: any AppCoordinating,
        launchAtLoginController: any LaunchAtLoginControlling = LaunchAtLoginController(),
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) {
        self.coordinator = coordinator
        self.launchAtLoginController = launchAtLoginController

        let initialSettings = settings ?? coordinator.settings
        let initialSnapshot = snapshot ?? coordinator.snapshot
        self.settings = initialSettings
        self.snapshot = initialSnapshot

        isReminderWindowPresented = Self.isReminderWindowPresented(for: initialSnapshot)

        startObservingStateChanges()
    }

    static func makeForTests(
        coordinator: any AppCoordinating = AppCoordinator(),
        launchAtLoginController: any LaunchAtLoginControlling = LaunchAtLoginController(),
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

    func start() {
        guard !hasStartedCoordinator else {
            return
        }

        hasStartedCoordinator = true
        _ = launchAtLoginController.setEnabled(settings.launchAtLogin)
        startObservingStateChanges()
        coordinator.start()
    }

    func stop() {
        stopObservingStateChanges()

        guard hasStartedCoordinator else {
            return
        }

        hasStartedCoordinator = false
        coordinator.stop()
    }

    func pauseReminders() {
        coordinator.pauseReminders()
    }

    func resumeReminders() {
        coordinator.resumeReminders()
    }

    func skipCurrentReminder() {
        coordinator.skipCurrentReminder()
    }

    func skipCurrentBreak() {
        coordinator.skipCurrentBreak()
    }

    func startBreakNow() {
        coordinator.startBreakNow()
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        coordinator.updateSettings(settings)
    }

    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> String? {
        var updatedSettings = settings
        updatedSettings.launchAtLogin = enabled
        updateSettings(updatedSettings)
        return launchAtLoginController.setEnabled(enabled)
    }

    private func applyState(snapshot: AppSnapshot, settings: AppSettings) {
        self.snapshot = snapshot
        self.settings = settings
        isReminderWindowPresented = Self.isReminderWindowPresented(for: snapshot)
    }

    private func stopObservingStateChanges() {
        guard let stateChangeObservation else {
            return
        }

        stateChangeObservation.cancel()
        self.stateChangeObservation = nil
    }

    private func startObservingStateChanges() {
        guard stateChangeObservation == nil else {
            return
        }

        stateChangeObservation = StateChangeObservation(
            coordinator: coordinator,
            token: coordinator.observeStateChanges { [weak self] snapshot, settings in
                self?.applyState(snapshot: snapshot, settings: settings)
            }
        )
    }

    private static func isReminderWindowPresented(for snapshot: AppSnapshot) -> Bool {
        snapshot.phase == .waitingForIdle
    }

    struct ReminderWindowState: Equatable {
        let breakType: BreakType
        let breakDuration: TimeInterval
        let idleDuration: TimeInterval
        let idleThreshold: TimeInterval
    }

    struct BreakOverlayState: Equatable {
        let remainingSeconds: Int
        let totalSeconds: Int
    }
}

private final class StateChangeObservation {
    private weak var coordinator: (any AppCoordinating)?
    private var token: AppStateObservationToken?

    init(coordinator: any AppCoordinating, token: AppStateObservationToken) {
        self.coordinator = coordinator
        self.token = token
    }

    func cancel() {
        guard let coordinator, let token else {
            return
        }

        coordinator.removeStateChangeObserver(token)
        self.token = nil
    }

    deinit {
        cancel()
    }
}
