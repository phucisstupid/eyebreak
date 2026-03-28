import Foundation

enum SchedulerEvent {
    case tick(activeDelta: TimeInterval, idleDuration: TimeInterval)
    case pause
    case resume
    case skipReminder
    case sleep
    case wake
}
