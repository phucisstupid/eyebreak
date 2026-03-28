import Foundation

struct AppSnapshot: Codable, Equatable {
    var phase: AppPhase
    var breakCount: Int
    var nextBreakType: BreakType
    var breakSessionState: BreakSessionState?
    var schedulerState: SchedulerState
    var idleDuration: TimeInterval
    var postpone: ReminderPostpone?

    var remainingBreakSeconds: Int {
        guard let breakSessionState else {
            return 0
        }

        return Int(ceil(breakSessionState.remainingDuration))
    }

    static func initial(settings: AppSettings) -> AppSnapshot {
        let breakCount = 0

        return AppSnapshot(
            phase: .running,
            breakCount: breakCount,
            nextBreakType: .next(afterCompletedBreakCount: breakCount, using: settings),
            breakSessionState: nil,
            schedulerState: .running(progress: 0),
            idleDuration: 0,
            postpone: nil
        )
    }

    static func waitingForIdle(
        progress: TimeInterval,
        breakCount: Int,
        nextBreakType: BreakType
    ) -> AppSnapshot {
        AppSnapshot(
            phase: .waitingForIdle,
            breakCount: breakCount,
            nextBreakType: nextBreakType,
            breakSessionState: nil,
            schedulerState: .waitingForIdle(progress: progress),
            idleDuration: 0,
            postpone: nil
        )
    }
}
