import AppKit
import SwiftUI

@main
struct EyeBreakApp: App {
    static let reminderWindowID = "reminder"

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @StateObject private var appModel: AppModel
    @State private var reminderWindowRouter = ReminderWindowRouter()
    private let breakOverlayPresenter = BreakOverlayPresenter()
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
        .onChange(of: appModel.isReminderWindowPresented, initial: true) { _, isPresented in
            applyReminderWindowAction(
                reminderWindowRouter.updateDesiredPresentation(isPresented)
            )
        }
        .onChange(of: appModel.breakOverlayState, initial: true) { _, state in
            renderBreakOverlay(state)
        }

        WindowGroup(id: Self.reminderWindowID) {
            ReminderWindowSceneView(
                model: appModel,
                onWindowVisibilityChange: handleReminderWindowVisibilityChange
            )
        }
        .defaultSize(width: 328, height: 170)
        .windowResizability(.contentSize)

        Settings {
            PreferencesView(
                settings: appModel.settings,
                onSave: appModel.updateSettings,
                onLaunchAtLoginChange: appModel.setLaunchAtLogin
            )
        }
    }

    private func handleReminderWindowVisibilityChange(_ isVisible: Bool) {
        applyReminderWindowAction(
            reminderWindowRouter.updateWindowVisibility(isVisible)
        )
    }

    private func applyReminderWindowAction(_ action: ReminderWindowRouter.Action) {
        switch action {
        case .open:
            openWindow(id: Self.reminderWindowID)
        case .dismiss:
            dismissWindow(id: Self.reminderWindowID)
        case .none:
            break
        }
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

@MainActor
struct ReminderWindowRouter {
    enum Action: Equatable {
        case open
        case dismiss
        case none
    }

    private(set) var desiredPresentation = false
    private(set) var isWindowVisible = false

    mutating func updateDesiredPresentation(_ desiredPresentation: Bool) -> Action {
        self.desiredPresentation = desiredPresentation

        if desiredPresentation {
            return isWindowVisible ? .none : .open
        }

        return isWindowVisible ? .dismiss : .none
    }

    mutating func updateWindowVisibility(_ isWindowVisible: Bool) -> Action {
        self.isWindowVisible = isWindowVisible

        if !isWindowVisible, desiredPresentation {
            return .open
        }

        return .none
    }
}
