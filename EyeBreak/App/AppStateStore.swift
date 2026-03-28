import Foundation

final class AppStateStore {
    let settings: AppSettings
    let scheduler: BreakScheduler
    let breakSessionManager: BreakSessionManager
    private(set) var snapshot: AppSnapshot

    init(settings: AppSettings, snapshot: AppSnapshot? = nil) {
        self.settings = settings
        scheduler = BreakScheduler(settings: settings)
        breakSessionManager = BreakSessionManager(settings: settings)
        self.snapshot = snapshot ?? .initial(settings: settings)
    }

    func updateSnapshot(_ snapshot: AppSnapshot) {
        self.snapshot = snapshot
    }
}
