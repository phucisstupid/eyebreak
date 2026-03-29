import Foundation

struct MenuContent: Equatable {
    var statusLine: String
    var timeUntilNextReminderLine: String
    var waitingForIdleLine: String
    var breakCountLine: String
    var nextBreakTypeLine: String
    var canStartBreakNow: Bool
    var canPause: Bool
    var canResume: Bool
    var canSkipReminder: Bool
}
