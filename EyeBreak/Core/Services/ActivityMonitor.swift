import Foundation

final class ActivityMonitor {
    private let idleTimeProvider: any IdleTimeProviding

    init(idleTimeProvider: any IdleTimeProviding) {
        self.idleTimeProvider = idleTimeProvider
    }

    func currentIdleDuration() -> TimeInterval {
        max(idleTimeProvider.currentIdleTime(), 0)
    }
}
