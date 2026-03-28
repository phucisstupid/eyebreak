import Foundation

final class MenuContentBuilder {
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    func build(from snapshot: AppSnapshot, settings: AppSettings) -> MenuContent {
        MenuContent(
            statusLine: statusLine(for: snapshot),
            timeUntilNextReminderLine: timeUntilNextReminderLine(for: snapshot, settings: settings),
            waitingForIdleLine: waitingForIdleLine(for: snapshot),
            breakCountLine: "Current break count: \(snapshot.breakCount)",
            nextBreakTypeLine: "Next break type: \(nextBreakType(for: snapshot).menuLabel)",
            canPause: snapshot.phase != .paused && snapshot.phase != .breakInProgress,
            canResume: snapshot.phase == .paused,
            canSkipReminder: snapshot.phase == .waitingForIdle
        )
    }

    private func statusLine(for snapshot: AppSnapshot) -> String {
        switch snapshot.phase {
        case .running:
            return snapshot.postpone == nil ? "Tracking active time" : "Reminder postponed"
        case .waitingForIdle:
            return "Reminder ready"
        case .paused:
            return "Reminders paused"
        case .breakInProgress:
            return "Break in progress"
        }
    }

    private func timeUntilNextReminderLine(
        for snapshot: AppSnapshot,
        settings: AppSettings
    ) -> String {
        let remainingSeconds = remainingReminderSeconds(for: snapshot, settings: settings)
        return "Time until next reminder: \(formatDuration(remainingSeconds))"
    }

    private func waitingForIdleLine(for snapshot: AppSnapshot) -> String {
        "Waiting for idle: \(snapshot.phase == .waitingForIdle ? "Yes" : "No")"
    }

    private func nextBreakType(for snapshot: AppSnapshot) -> BreakType {
        snapshot.breakSessionState?.breakType ?? snapshot.nextBreakType
    }

    private func remainingReminderSeconds(for snapshot: AppSnapshot, settings: AppSettings) -> Int {
        if let postpone = snapshot.postpone, snapshot.phase == .running {
            return max(Int(ceil(postpone.endsAt.timeIntervalSince(now()))), 0)
        }

        if snapshot.phase == .breakInProgress {
            return Int(settings.activeInterval)
        }

        switch snapshot.schedulerState {
        case .running(let progress):
            return max(Int(ceil(settings.activeInterval - progress)), 0)
        case .waitingForIdle:
            return 0
        case .paused(let progress, let origin):
            switch origin {
            case .running:
                return max(Int(ceil(settings.activeInterval - progress)), 0)
            case .waitingForIdle:
                return 0
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

extension BreakType {
    fileprivate var menuLabel: String {
        switch self {
        case .short:
            return "Short"
        case .long:
            return "Long"
        }
    }
}
