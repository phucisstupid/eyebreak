import Foundation

final class AppCoordinator: AppCoordinating {
    private let settingsStore: any SettingsStore
    private let activityMonitor: ActivityMonitor
    private let heartbeat: Heartbeat
    private let sleepWakeObserver: SleepWakeObserver
    private let now: () -> Date
    private(set) var store: AppStateStore
    private var stateChangeObservers:
        [AppStateObservationToken: (AppSnapshot, AppSettings) -> Void] = [:]
    private var legacyStateChangeObserverToken: AppStateObservationToken?

    var onStateChange: ((AppSnapshot, AppSettings) -> Void)? {
        didSet {
            if let legacyStateChangeObserverToken {
                removeStateChangeObserver(legacyStateChangeObserverToken)
                self.legacyStateChangeObserverToken = nil
            }

            guard let onStateChange else {
                return
            }

            let callback = onStateChange
            legacyStateChangeObserverToken = observeStateChanges { snapshot, settings in
                callback(snapshot, settings)
            }
        }
    }

    var settings: AppSettings {
        store.settings
    }

    var snapshot: AppSnapshot {
        store.snapshot
    }

    func observeStateChanges(
        _ observer: @escaping (AppSnapshot, AppSettings) -> Void
    ) -> AppStateObservationToken {
        let token = AppStateObservationToken()
        stateChangeObservers[token] = observer
        return token
    }

    func removeStateChangeObserver(_ token: AppStateObservationToken) {
        stateChangeObservers[token] = nil
    }

    init(
        settingsStore: any SettingsStore = UserDefaultsSettingsStore(),
        idleTimeProvider: any IdleTimeProviding = SystemIdleTimeProvider(),
        heartbeat: Heartbeat = Heartbeat(),
        sleepWakeObserver: SleepWakeObserver = SleepWakeObserver(),
        now: @escaping () -> Date = Date.init
    ) {
        self.settingsStore = settingsStore
        let settings = settingsStore.load() ?? .default
        activityMonitor = ActivityMonitor(idleTimeProvider: idleTimeProvider)
        self.heartbeat = heartbeat
        self.sleepWakeObserver = sleepWakeObserver
        self.now = now
        store = AppStateStore(settings: settings)

        self.heartbeat.onTick = { [weak self] delta in
            self?.handleHeartbeat(delta: delta)
        }
        self.sleepWakeObserver.onSleep = { [weak self] in
            self?.handleSleep()
        }
        self.sleepWakeObserver.onWake = { [weak self] in
            self?.handleWake()
        }
    }

    func start() {
        sleepWakeObserver.start()
        heartbeat.start()
        publishState()
    }

    func stop() {
        heartbeat.stop()
        sleepWakeObserver.stop()
    }

    func handleHeartbeat(delta: TimeInterval) {
        let idleDuration = activityMonitor.currentIdleDuration()
        let nextSnapshot = reduceHeartbeat(
            snapshot: store.snapshot,
            delta: delta,
            idleDuration: idleDuration,
            now: now()
        )

        store.updateSnapshot(nextSnapshot)
        publishState()
    }

    func replaceSnapshotForTesting(_ snapshot: AppSnapshot) {
        store.updateSnapshot(snapshot)
        publishState()
    }

    func pauseReminders() {
        applyScheduler(event: .pause)
    }

    func resumeReminders() {
        applyScheduler(event: .resume)
    }

    func skipCurrentReminder() {
        applyScheduler(event: .skipReminder)
    }

    func postponeCurrentReminder() {
        guard case .waitingForIdle = store.snapshot.schedulerState else {
            return
        }

        var snapshot = store.snapshot
        snapshot.breakSessionState = nil
        snapshot.postpone = .standard(from: now())
        snapshot.schedulerState = .running(progress: 0)
        snapshot.phase = phase(for: snapshot)
        store.updateSnapshot(snapshot)
        publishState()
    }

    func skipCurrentBreak() {
        guard store.snapshot.breakSessionState != nil else {
            return
        }

        var snapshot = store.snapshot
        snapshot.breakSessionState = nil
        snapshot.postpone = nil
        snapshot.schedulerState = .running(progress: 0)
        snapshot.phase = phase(for: snapshot)
        store.updateSnapshot(snapshot)
        publishState()
    }

    func postponeCurrentBreak() {
        guard let session = store.snapshot.breakSessionState else {
            return
        }

        var snapshot = store.snapshot
        let result = store.breakSessionManager.postpone(session: session, now: now())
        snapshot.breakSessionState = result.nextSession
        snapshot.postpone = result.postpone
        snapshot.schedulerState = .running(progress: 0)
        snapshot.phase = phase(for: snapshot)
        store.updateSnapshot(snapshot)
        publishState()
    }

    func startBreakNow() {
        let progress: TimeInterval

        switch store.snapshot.schedulerState {
        case .running(let currentProgress):
            progress = currentProgress
        case .waitingForIdle(let currentProgress):
            progress = currentProgress
        case .paused:
            return
        }

        var snapshot = store.snapshot
        snapshot.breakSessionState = store.breakSessionManager.startBreak(
            completedBreakCount: snapshot.breakCount,
            startedAt: now()
        )
        snapshot.postpone = nil
        snapshot.schedulerState = .running(progress: progress)
        snapshot.phase = .breakInProgress
        store.updateSnapshot(snapshot)
        publishState()
    }

    func updateSettings(_ settings: AppSettings) {
        settingsStore.save(settings)

        let currentSnapshot = store.snapshot
        let nextStore = AppStateStore(settings: settings)
        var nextSnapshot = adjustedSnapshot(currentSnapshot, for: settings)
        nextSnapshot.phase = phase(for: nextSnapshot)

        store = nextStore
        store.updateSnapshot(nextSnapshot)
        publishState()
    }

    private func handleSleep() {
        heartbeat.stop()
        applyScheduler(event: .sleep)
    }

    private func handleWake() {
        applyScheduler(event: .wake)
        heartbeat.start()
    }

    private func applyScheduler(event: SchedulerEvent) {
        var snapshot = store.snapshot
        let result = store.scheduler.reduce(state: snapshot.schedulerState, event: event)
        snapshot.schedulerState = result.state
        snapshot.phase = phase(for: snapshot)
        store.updateSnapshot(snapshot)
        publishState()
    }

    private func adjustedSnapshot(
        _ snapshot: AppSnapshot,
        for settings: AppSettings
    ) -> AppSnapshot {
        var nextSnapshot = snapshot
        nextSnapshot.nextBreakType = BreakType.next(
            afterCompletedBreakCount: snapshot.breakCount,
            using: settings
        )

        switch snapshot.schedulerState {
        case .running(let progress):
            if progress >= settings.activeInterval {
                nextSnapshot.schedulerState = .waitingForIdle(progress: settings.activeInterval)
            } else {
                nextSnapshot.schedulerState = .running(progress: progress)
            }
        case .waitingForIdle(let progress):
            nextSnapshot.schedulerState = .waitingForIdle(
                progress: min(progress, settings.activeInterval))
        case .paused(let progress, let origin):
            let clampedProgress = min(progress, settings.activeInterval)
            let nextOrigin: SchedulerPauseOrigin
            if origin == .running, clampedProgress >= settings.activeInterval {
                nextOrigin = .waitingForIdle
            } else {
                nextOrigin = origin
            }

            nextSnapshot.schedulerState = .paused(progress: clampedProgress, origin: nextOrigin)
        }

        return nextSnapshot
    }

    private func reduceHeartbeat(
        snapshot: AppSnapshot,
        delta: TimeInterval,
        idleDuration: TimeInterval,
        now: Date
    ) -> AppSnapshot {
        var nextSnapshot = snapshot
        nextSnapshot.idleDuration = idleDuration

        if let postpone = nextSnapshot.postpone {
            if now < postpone.endsAt {
                nextSnapshot.phase = phase(for: nextSnapshot)
                return nextSnapshot
            }

            nextSnapshot.postpone = nil
        }

        if let session = nextSnapshot.breakSessionState {
            let result = store.breakSessionManager.tick(session: session, delta: delta)
            nextSnapshot.breakSessionState = result.nextSession
            nextSnapshot.breakCount += result.completedBreakCountDelta
            nextSnapshot.nextBreakType = BreakType.next(
                afterCompletedBreakCount: nextSnapshot.breakCount,
                using: store.settings
            )

            if result.nextSession == nil {
                nextSnapshot.schedulerState = .running(progress: 0)
            }

            nextSnapshot.phase = phase(for: nextSnapshot)
            return nextSnapshot
        }

        if idleDuration >= store.settings.idleThreshold {
            if case .waitingForIdle(let progress) = nextSnapshot.schedulerState {
                nextSnapshot.breakSessionState = store.breakSessionManager.startBreak(
                    completedBreakCount: nextSnapshot.breakCount,
                    startedAt: now
                )
                nextSnapshot.schedulerState = .running(progress: progress)
                nextSnapshot.phase = .breakInProgress
                return nextSnapshot
            }
        }

        let result = store.scheduler.reduce(
            state: nextSnapshot.schedulerState,
            event: .tick(activeDelta: delta, idleDuration: idleDuration)
        )
        nextSnapshot.schedulerState = result.state
        nextSnapshot.phase = phase(for: nextSnapshot)
        return nextSnapshot
    }

    private func phase(for snapshot: AppSnapshot) -> AppPhase {
        if snapshot.breakSessionState != nil {
            return .breakInProgress
        }

        switch snapshot.schedulerState {
        case .running:
            return .running
        case .waitingForIdle:
            return .waitingForIdle
        case .paused:
            return .paused
        }
    }

    private func publishState() {
        let snapshot = store.snapshot
        let settings = store.settings

        for observer in stateChangeObservers.values {
            observer(snapshot, settings)
        }
    }

    deinit { stop() }
}
