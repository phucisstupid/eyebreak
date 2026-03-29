import Foundation

typealias AppStateObservationToken = UUID

protocol AppCoordinating: AnyObject {
    var settings: AppSettings { get }
    var snapshot: AppSnapshot { get }

    func observeStateChanges(
        _ observer: @escaping (AppSnapshot, AppSettings) -> Void
    ) -> AppStateObservationToken

    func removeStateChangeObserver(_ token: AppStateObservationToken)

    func start()
    func stop()
    func pauseReminders()
    func resumeReminders()
    func skipCurrentReminder()
    func postponeCurrentReminder()
    func skipCurrentBreak()
    func postponeCurrentBreak()
    func startBreakNow()
    func updateSettings(_ settings: AppSettings)
}
