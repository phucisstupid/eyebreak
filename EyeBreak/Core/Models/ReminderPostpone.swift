import Foundation

struct ReminderPostpone: Equatable, Codable {
    var startedAt: Date
    var duration: TimeInterval

    var endsAt: Date {
        startedAt.addingTimeInterval(duration)
    }

    static let standardDuration: TimeInterval = 5 * 60

    static func standard(from startedAt: Date) -> ReminderPostpone {
        ReminderPostpone(startedAt: startedAt, duration: standardDuration)
    }
}
