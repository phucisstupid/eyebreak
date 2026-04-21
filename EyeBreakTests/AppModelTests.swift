import XCTest

@testable import EyeBreak

@MainActor
final class AppModelTests: XCTestCase {
    func test_initialSnapshotDefaultsToCoordinatorSnapshot() {
        let coordinator = SpyAppCoordinator(
            settings: AppSettings.default,
            snapshot: .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )

        let model = AppModel.makeForTests(coordinator: coordinator)

        XCTAssertEqual(model.snapshot.phase, .waitingForIdle)
        XCTAssertEqual(
            model.reminderWindowState,
            AppModel.ReminderWindowState(
                breakType: .short,
                breakDuration: 20,
                idleDuration: 0,
                idleThreshold: 5
            )
        )
        XCTAssertNil(model.breakOverlayState)
    }

    func test_stateChangeObserverPublishesReminderWindowState() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let model = AppModel.makeForTests(coordinator: coordinator)

        coordinator.emitStateChange(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )

        XCTAssertEqual(
            model.reminderWindowState,
            AppModel.ReminderWindowState(
                breakType: .short,
                breakDuration: 20,
                idleDuration: 0,
                idleThreshold: 5
            )
        )
        XCTAssertNil(model.breakOverlayState)
    }

    func test_stateChangeObserverPublishesBreakOverlayState() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let model = AppModel.makeForTests(coordinator: coordinator)

        coordinator.emitStateChange(.fixtureBreakInProgress(remaining: 20))

        XCTAssertNil(model.reminderWindowState)
        XCTAssertEqual(model.breakOverlayState?.remainingSeconds, 20)
        XCTAssertEqual(model.breakOverlayState?.totalSeconds, 20)
    }

    func test_stateChangesReachMultipleObservers() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let model = AppModel.makeForTests(coordinator: coordinator)
        let expectation = expectation(description: "secondary observer")
        var observedSnapshots: [AppSnapshot] = []

        let token = coordinator.observeStateChanges { snapshot, _ in
            observedSnapshots.append(snapshot)
            expectation.fulfill()
        }

        coordinator.emitStateChange(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short))
        wait(for: [expectation], timeout: 1)
        coordinator.removeStateChangeObserver(token)

        XCTAssertNotNil(model.reminderWindowState)
        XCTAssertEqual(observedSnapshots.count, 1)
        XCTAssertEqual(observedSnapshots.first?.phase, .waitingForIdle)
    }

    func test_deinitRemovesStateChangeObserver() {
        let coordinator = SpyAppCoordinator(settings: .default)
        weak var weakModel: AppModel?

        autoreleasepool {
            let model = AppModel.makeForTests(coordinator: coordinator)
            weakModel = model
            XCTAssertEqual(coordinator.observerCount, 1)
        }

        XCTAssertNil(weakModel)
        XCTAssertEqual(coordinator.observerCount, 0)
    }

    func test_startStopStartRestoresStateChangeObservation() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let model = AppModel.makeForTests(coordinator: coordinator)

        XCTAssertEqual(coordinator.observerCount, 1)

        model.stop()

        XCTAssertEqual(coordinator.observerCount, 0)

        coordinator.emitStateChange(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short))

        XCTAssertEqual(model.snapshot.phase, .running)

        model.start()

        XCTAssertEqual(coordinator.observerCount, 1)

        coordinator.emitStateChange(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short))

        XCTAssertNotNil(model.reminderWindowState)
        XCTAssertNil(model.breakOverlayState)
    }

    func test_legacyCoordinatorOnStateChangeBridgeReceivesPublishedState() {
        let coordinator = AppCoordinator(
            settingsStore: InMemorySettingsStore(),
            idleTimeProvider: StubIdleTimeProvider(idleTime: 0)
        )
        let expectation = expectation(description: "legacy onStateChange callback")
        var receivedSnapshot: AppSnapshot?
        var receivedSettings: AppSettings?

        coordinator.onStateChange = { snapshot, settings in
            receivedSnapshot = snapshot
            receivedSettings = settings
            expectation.fulfill()
        }

        coordinator.replaceSnapshotForTesting(
            .waitingForIdle(progress: 1_200, breakCount: 0, nextBreakType: .short)
        )

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(receivedSnapshot?.phase, .waitingForIdle)
        XCTAssertEqual(receivedSettings, coordinator.settings)
    }

    func test_startReappliesPersistedLaunchAtLoginSetting() {
        let coordinator = SpyAppCoordinator(
            settings: AppSettings(
                activeInterval: 20 * 60,
                shortBreakDuration: 20,
                longBreakDuration: 60,
                longBreakFrequency: 3,
                idleThreshold: 5,
                launchAtLogin: true
            )
        )
        let launchAtLoginController = SpyLaunchAtLoginController()
        let model = AppModel.makeForTests(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController
        )

        model.start()

        XCTAssertEqual(launchAtLoginController.enabledValues, [true])
        XCTAssertEqual(coordinator.startCallCount, 1)
    }

    func test_startForwardsToCoordinatorOnlyOnceWhenCalledTwice() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let launchAtLoginController = SpyLaunchAtLoginController()
        let model = AppModel.makeForTests(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController
        )

        model.start()
        model.start()

        XCTAssertEqual(coordinator.startCallCount, 1)
        XCTAssertEqual(launchAtLoginController.enabledValues, [false])
    }

    func test_lifecycleControllerStopsModelSynchronouslyWhenTerminationIsHandled() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let model = AppModel.makeForTests(coordinator: coordinator)
        let lifecycleController = AppLifecycleController(
            model: model,
            isRunningTests: false,
            notificationCenter: NotificationCenter()
        )

        lifecycleController.startIfNeeded()
        lifecycleController.handleWillTerminate()

        XCTAssertEqual(coordinator.startCallCount, 1)
        XCTAssertEqual(coordinator.stopCallCount, 1)
    }
}

private final class SpyAppCoordinator: AppCoordinating {
    var settings: AppSettings
    var snapshot: AppSnapshot
    var startCallCount = 0
    var stopCallCount = 0
    var pauseRemindersCallCount = 0
    var resumeRemindersCallCount = 0
    var skipCurrentReminderCallCount = 0
    var postponeCurrentReminderCallCount = 0
    var skipCurrentBreakCallCount = 0
    var postponeCurrentBreakCallCount = 0
    var startBreakNowCallCount = 0
    var updateSettingsValues: [AppSettings] = []
    private var observers: [AppStateObservationToken: (AppSnapshot, AppSettings) -> Void] = [:]

    var observerCount: Int {
        observers.count
    }

    init(settings: AppSettings, snapshot: AppSnapshot? = nil) {
        self.settings = settings
        self.snapshot = snapshot ?? .initial(settings: settings)
    }

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func pauseReminders() {
        pauseRemindersCallCount += 1
    }

    func resumeReminders() {
        resumeRemindersCallCount += 1
    }

    func skipCurrentReminder() {
        skipCurrentReminderCallCount += 1
    }

    func postponeCurrentReminder() {
        postponeCurrentReminderCallCount += 1
    }

    func skipCurrentBreak() {
        skipCurrentBreakCallCount += 1
    }

    func postponeCurrentBreak() {
        postponeCurrentBreakCallCount += 1
    }

    func startBreakNow() {
        startBreakNowCallCount += 1
    }

    func updateSettings(_ settings: AppSettings) {
        updateSettingsValues.append(settings)
        self.settings = settings
    }

    func observeStateChanges(
        _ observer: @escaping (AppSnapshot, AppSettings) -> Void
    ) -> AppStateObservationToken {
        let token = AppStateObservationToken()
        observers[token] = observer
        return token
    }

    func removeStateChangeObserver(_ token: AppStateObservationToken) {
        observers[token] = nil
    }

    func emitStateChange(_ snapshot: AppSnapshot, settings: AppSettings? = nil) {
        let nextSettings = settings ?? self.settings
        self.snapshot = snapshot
        self.settings = nextSettings

        for observer in observers.values {
            observer(snapshot, nextSettings)
        }
    }
}

private final class SpyLaunchAtLoginController: LaunchAtLoginControlling {
    private(set) var enabledValues: [Bool] = []

    func setEnabled(_ enabled: Bool) -> String? {
        enabledValues.append(enabled)
        return nil
    }
}

private final class InMemorySettingsStore: SettingsStore {
    private var settings: AppSettings?

    init(settings: AppSettings? = .default) {
        self.settings = settings
    }

    func load() -> AppSettings? {
        settings
    }

    func save(_ settings: AppSettings) {
        self.settings = settings
    }
}

private struct StubIdleTimeProvider: IdleTimeProviding {
    var idleTime: TimeInterval

    func currentIdleTime() -> TimeInterval {
        idleTime
    }
}

extension AppSnapshot {
    fileprivate static func fixtureBreakInProgress(remaining: Int) -> AppSnapshot {
        AppSnapshot(
            phase: .breakInProgress,
            breakCount: 0,
            nextBreakType: .short,
            breakSessionState: BreakSessionState(
                breakType: .short,
                remainingDuration: TimeInterval(remaining),
                startedAt: Date(timeIntervalSince1970: 0)
            ),
            schedulerState: .running(progress: 1_200),
            idleDuration: 0,
            postpone: nil
        )
    }
}

extension AppModel {
    static func makeForTests(
        coordinator: any AppCoordinating = SpyAppCoordinator(settings: .default),
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
}
