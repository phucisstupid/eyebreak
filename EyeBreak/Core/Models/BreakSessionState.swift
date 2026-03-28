import Foundation

struct BreakSessionState: Equatable, Codable {
    var breakType: BreakType
    var remainingDuration: TimeInterval
    var startedAt: Date
}
