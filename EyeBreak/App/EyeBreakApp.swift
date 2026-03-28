import AppKit
import SwiftUI

@main
struct EyeBreakApp: App {
    @StateObject private var appModel: AppModel
    private let breakOverlayPresenter = BreakOverlayPresenter()
    private let reminderPopupPresenter = ReminderPopupPresenter()
    private let lifecycleController: AppLifecycleController

    init() {
        let coordinator = AppCoordinator()
        let launchAtLoginController = LaunchAtLoginController()
        let model = AppModel(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController
        )
        lifecycleController = AppLifecycleController(
            model: model,
            isRunningTests: Self.isRunningTests
        )
        lifecycleController.startIfNeeded()

        _appModel = StateObject(
            wrappedValue: model
        )
    }

    var body: some Scene {
        MenuBarExtra("EyeBreak", systemImage: "eye") {
            MenuBarContentView(
                model: appModel,
                quit: { NSApp.terminate(nil) }
            )
        }
        .onChange(of: appModel.reminderWindowState, initial: true) { _, state in
            renderReminderPopup(state)
        }
        .onChange(of: appModel.breakOverlayState, initial: true) { _, state in
            renderBreakOverlay(state)
        }

        Settings {
            PreferencesView(
                settings: appModel.settings,
                onSave: appModel.updateSettings,
                onLaunchAtLoginChange: appModel.setLaunchAtLogin
            )
        }
    }

    private func renderReminderPopup(_ state: AppModel.ReminderWindowState?) {
        reminderPopupPresenter.render(
            isPresented: state != nil,
            breakType: state?.breakType ?? .short,
            breakDuration: state?.breakDuration ?? 0,
            idleDuration: state?.idleDuration ?? 0,
            idleThreshold: state?.idleThreshold ?? 1,
            onStartNow: appModel.startBreakNow,
            onSkip: appModel.skipCurrentReminder
        )
    }

    private func renderBreakOverlay(_ state: AppModel.BreakOverlayState?) {
        breakOverlayPresenter.render(
            isPresented: state != nil,
            remainingSeconds: state?.remainingSeconds ?? 0,
            totalSeconds: state?.totalSeconds ?? 0,
            onSkip: appModel.skipCurrentBreak
        )
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

@MainActor
final class AppLifecycleController {
    private let model: AppModel
    private let isRunningTests: Bool
    private let notificationCenter: NotificationCenter
    private let terminationNotificationName: Notification.Name
    private var terminationObserver: NSObjectProtocol?

    init(
        model: AppModel,
        isRunningTests: Bool,
        notificationCenter: NotificationCenter = .default,
        terminationNotificationName: Notification.Name = NSApplication.willTerminateNotification
    ) {
        self.model = model
        self.isRunningTests = isRunningTests
        self.notificationCenter = notificationCenter
        self.terminationNotificationName = terminationNotificationName
        registerTerminationObserver()
    }

    func startIfNeeded() {
        guard !isRunningTests else {
            return
        }

        model.start()
    }

    func handleWillTerminate() {
        model.stop()
    }

    private func registerTerminationObserver() {
        terminationObserver = notificationCenter.addObserver(
            forName: terminationNotificationName,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleWillTerminate()
            }
        }
    }
}
