import Foundation

struct ReminderPostpone: Equatable, Codable {
    var startedAt: Date
    var duration: TimeInterval

    var endsAt: Date {
        startedAt.addingTimeInterval(duration)
    }
}
