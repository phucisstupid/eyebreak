import Foundation

struct BreakTickResult: Equatable {
    var nextSession: BreakSessionState?
    var completedBreakCountDelta: Int
    var completedBreakType: BreakType?
    var completedAt: Date?
}

struct BreakSkipResult: Equatable {
    var nextSession: BreakSessionState?
    var completedBreakCountDelta: Int
    var postpone: ReminderPostpone?

    var postponeDuration: TimeInterval {
        postpone?.duration ?? 0
    }
}

final class BreakSessionManager {
    let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func startBreak(completedBreakCount: Int, startedAt: Date) -> BreakSessionState {
        let breakType = BreakType.next(
            afterCompletedBreakCount: completedBreakCount,
            using: settings
        )

        return BreakSessionState(
            breakType: breakType,
            remainingDuration: breakType.duration(using: settings),
            startedAt: startedAt
        )
    }

    func tick(session: BreakSessionState, delta: TimeInterval) -> BreakTickResult {
        let remainingDelta = max(delta, 0)
        let nextDuration = max(session.remainingDuration - remainingDelta, 0)

        if nextDuration == 0 {
            return BreakTickResult(
                nextSession: nil,
                completedBreakCountDelta: 1,
                completedBreakType: session.breakType,
                completedAt: session.startedAt.addingTimeInterval(
                    session.breakType.duration(using: settings))
            )
        }

        return BreakTickResult(
            nextSession: BreakSessionState(
                breakType: session.breakType,
                remainingDuration: nextDuration,
                startedAt: session.startedAt
            ),
            completedBreakCountDelta: 0,
            completedBreakType: nil,
            completedAt: nil
        )
    }

    func skip(session _: BreakSessionState, now: Date) -> BreakSkipResult {
        let postpone = ReminderPostpone(
            startedAt: now,
            duration: Self.skipPostponeDuration
        )

        return BreakSkipResult(
            nextSession: nil,
            completedBreakCountDelta: 0,
            postpone: postpone
        )
    }

    private static let skipPostponeDuration: TimeInterval = 5 * 60
}
