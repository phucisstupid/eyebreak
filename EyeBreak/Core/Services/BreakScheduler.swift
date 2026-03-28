import Foundation

enum SchedulerState: Equatable, Codable {
    case running(progress: TimeInterval)
    case waitingForIdle(progress: TimeInterval)
    case paused(progress: TimeInterval, origin: SchedulerPauseOrigin)
}

enum SchedulerPauseOrigin: Equatable, Codable {
    case running
    case waitingForIdle
}

struct SchedulerResult: Equatable {
    let state: SchedulerState
    let commands: [SchedulerCommand]
}

final class BreakScheduler {
    let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func reduce(state: SchedulerState, event: SchedulerEvent) -> SchedulerResult {
        switch event {
        case .tick(let activeDelta, let idleDuration):
            return reduceTick(state: state, activeDelta: activeDelta, idleDuration: idleDuration)
        case .pause:
            return reducePause(state: state)
        case .resume:
            return reduceResume(state: state)
        case .skipReminder:
            return reduceSkipReminder(state: state)
        case .sleep, .wake:
            return SchedulerResult(state: state, commands: [])
        }
    }

    private func reduceTick(
        state: SchedulerState,
        activeDelta: TimeInterval,
        idleDuration: TimeInterval
    ) -> SchedulerResult {
        guard case .running(let progress) = state else {
            return SchedulerResult(state: state, commands: [])
        }

        guard activeDelta > 0, idleDuration < settings.idleThreshold else {
            return SchedulerResult(state: .running(progress: progress), commands: [])
        }

        let nextProgress = min(progress + activeDelta, settings.activeInterval)
        if nextProgress >= settings.activeInterval {
            return SchedulerResult(
                state: .waitingForIdle(progress: settings.activeInterval),
                commands: [.showReminder]
            )
        }

        return SchedulerResult(state: .running(progress: nextProgress), commands: [])
    }

    private func reducePause(state: SchedulerState) -> SchedulerResult {
        switch state {
        case .running(let progress):
            return SchedulerResult(
                state: .paused(progress: progress, origin: .running), commands: [])
        case .waitingForIdle(let progress):
            return SchedulerResult(
                state: .paused(progress: progress, origin: .waitingForIdle), commands: [])
        case .paused:
            return SchedulerResult(state: state, commands: [])
        }
    }

    private func reduceResume(state: SchedulerState) -> SchedulerResult {
        guard case .paused(let progress, let origin) = state else {
            return SchedulerResult(state: state, commands: [])
        }

        switch origin {
        case .running:
            return SchedulerResult(state: .running(progress: progress), commands: [])
        case .waitingForIdle:
            return SchedulerResult(state: .waitingForIdle(progress: progress), commands: [])
        }
    }

    private func reduceSkipReminder(state: SchedulerState) -> SchedulerResult {
        guard case .waitingForIdle = state else {
            return SchedulerResult(state: state, commands: [])
        }

        return SchedulerResult(state: .running(progress: 0), commands: [.hideReminder])
    }
}
