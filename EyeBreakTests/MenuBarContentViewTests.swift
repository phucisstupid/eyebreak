import XCTest

@testable import EyeBreak

@MainActor
final class MenuBarContentViewTests: XCTestCase {
    func test_menuContentReflectsWaitingForIdleState() {
        let settings = AppSettings.default
        let snapshot = AppSnapshot.waitingForIdle(
            progress: settings.activeInterval,
            breakCount: 2,
            nextBreakType: .long
        )
        let coordinator = SpyAppCoordinator(settings: settings, snapshot: snapshot)
        let model = AppModel.makeForTests(coordinator: coordinator, snapshot: snapshot, settings: settings)
        let view = MenuBarContentView(
            model: model,
            quit: {}
        )

        XCTAssertEqual(view.menuContent.statusLine, "Reminder ready")
        XCTAssertEqual(
            view.menuContent.timeUntilNextReminderLine, "Time until next reminder: 00:00")
        XCTAssertEqual(view.menuContent.waitingForIdleLine, "Waiting for idle: Yes")
        XCTAssertEqual(view.menuContent.breakCountLine, "Current break count: 2")
        XCTAssertEqual(view.menuContent.nextBreakTypeLine, "Next break type: Long")
        XCTAssertTrue(view.menuContent.canStartBreakNow)
        XCTAssertTrue(view.menuContent.canPause)
        XCTAssertFalse(view.menuContent.canResume)
        XCTAssertTrue(view.menuContent.canSkipReminder)
    }

    func test_quitCommandInvokesClosure() {
        let coordinator = SpyAppCoordinator(settings: .default, snapshot: .running(progress: 0, breakCount: 0, nextBreakType: .short))
        let model = AppModel.makeForTests(coordinator: coordinator)
        var quitRequested = false
        let view = MenuBarContentView(
            model: model,
            quit: { quitRequested = true }
        )
        view.quit()
        XCTAssertTrue(quitRequested)
    }

    func test_settingsCommandInvokesClosure() {
        let coordinator = SpyAppCoordinator(settings: .default, snapshot: .running(progress: 0, breakCount: 0, nextBreakType: .short))
        let model = AppModel.makeForTests(coordinator: coordinator)
        var settingsOpened = false
        let view = MenuBarContentView(
            model: model,
            quit: {},
            openSettings: { settingsOpened = true }
        )

        view.openSettings()

        XCTAssertTrue(settingsOpened)
    }

    func test_settingsCommandDismissesMenuBeforeOpeningSettings() {
        let coordinator = SpyAppCoordinator(settings: .default, snapshot: .running(progress: 0, breakCount: 0, nextBreakType: .short))
        let model = AppModel.makeForTests(coordinator: coordinator)
        var dismissed = false
        var returnedFromShowSettings = false
        let settingsOpenedExpectation = expectation(
            description: "settings opens on a later main-loop turn"
        )
        let view = MenuBarContentView(
            model: model,
            quit: {},
            openSettings: {
                XCTAssertTrue(dismissed)
                XCTAssertTrue(returnedFromShowSettings)
                settingsOpenedExpectation.fulfill()
            }
        )

        view.showSettings(dismissMenu: {
            dismissed = true
        })

        returnedFromShowSettings = true

        XCTAssertTrue(dismissed)
        wait(for: [settingsOpenedExpectation], timeout: 1)
    }

    func test_menuBarRootViewUsesInjectedSettingsAction() {
        let coordinator = SpyAppCoordinator(settings: .default, snapshot: .running(progress: 0, breakCount: 0, nextBreakType: .short))
        let model = AppModel.makeForTests(coordinator: coordinator)
        var settingsOpened = false
        let view = MenuBarRootView(
            model: model,
            quit: {},
            openSettings: { settingsOpened = true }
        )

        view.openSettings()

        XCTAssertTrue(settingsOpened)
    }

    func test_pauseResumeToggleUsesPauseIconWhenRunning() {
        let coordinator = SpyAppCoordinator(settings: .default, snapshot: .running(progress: 0, breakCount: 0, nextBreakType: .short))
        let model = AppModel.makeForTests(coordinator: coordinator)
        let view = MenuBarContentView(
            model: model,
            quit: {}
        )

        XCTAssertTrue(view.menuContent.canStartBreakNow)
        XCTAssertEqual(view.pauseResumeIconName, "pause.fill")
        XCTAssertEqual(view.pauseResumeAccessibilityLabel, "Pause reminders")
        XCTAssertTrue(view.canTogglePauseResume)
    }

    func test_pauseResumeToggleUsesPlayIconWhenPaused() {
        let settings = AppSettings.default
        let snapshot = AppSnapshot(
            phase: .paused,
            breakCount: 0,
            nextBreakType: .short,
            breakSessionState: nil,
            schedulerState: .paused(progress: 120, origin: .running),
            idleDuration: 0,
            postpone: nil
        )
        let coordinator = SpyAppCoordinator(settings: settings, snapshot: snapshot)
        let model = AppModel.makeForTests(coordinator: coordinator, snapshot: snapshot, settings: settings)
        let view = MenuBarContentView(
            model: model,
            quit: {}
        )

        XCTAssertEqual(view.pauseResumeIconName, "play.fill")
        XCTAssertEqual(view.pauseResumeAccessibilityLabel, "Resume reminders")
        XCTAssertTrue(view.canTogglePauseResume)
    }

    func test_startBreakNowInvokesModelAction() {
        let settings = AppSettings.default
        let snapshot = AppSnapshot.waitingForIdle(
            progress: settings.activeInterval,
            breakCount: 0,
            nextBreakType: .short
        )
        let coordinator = SpyAppCoordinator(settings: settings, snapshot: snapshot)
        let model = AppModel.makeForTests(coordinator: coordinator, settings: settings)
        let view = MenuBarContentView(
            model: model,
            quit: {}
        )
        let dismissedExpectation = expectation(description: "menu dismissed before break starts")
        let startExpectation = expectation(description: "break action invoked asynchronously")
        coordinator.onStartBreakNow = {
            XCTAssertTrue(coordinator.dismissedMenu)
            startExpectation.fulfill()
        }

        view.startBreakNow {
            coordinator.dismissedMenu = true
            dismissedExpectation.fulfill()
        }

        wait(for: [dismissedExpectation, startExpectation], timeout: 1)
        XCTAssertEqual(coordinator.startBreakNowCallCount, 1)
        XCTAssertTrue(view.menuContent.canStartBreakNow)
    }
}

private final class SpyAppCoordinator: AppCoordinating {
    var settings: AppSettings
    var snapshot: AppSnapshot
    var startBreakNowCallCount = 0
    var dismissedMenu = false
    var onStartBreakNow: (() -> Void)?

    init(settings: AppSettings, snapshot: AppSnapshot) {
        self.settings = settings
        self.snapshot = snapshot
    }

    func observeStateChanges(
        _ observer: @escaping (AppSnapshot, AppSettings) -> Void
    ) -> AppStateObservationToken {
        UUID()
    }

    func removeStateChangeObserver(_ token: AppStateObservationToken) {}

    func start() {}

    func stop() {}

    func pauseReminders() {}

    func resumeReminders() {}

    func skipCurrentReminder() {}

    func postponeCurrentReminder() {}

    func skipCurrentBreak() {}

    func postponeCurrentBreak() {}

    func startBreakNow() {
        startBreakNowCallCount += 1
        onStartBreakNow?()
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
    }
}
