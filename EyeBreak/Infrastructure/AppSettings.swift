import Foundation

struct AppSettings: Equatable, Codable {
    var activeInterval: TimeInterval
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var longBreakFrequency: Int
    var idleThreshold: TimeInterval
    var launchAtLogin: Bool

    static let `default` = AppSettings(
        activeInterval: 20 * 60,
        shortBreakDuration: 20,
        longBreakDuration: 60,
        longBreakFrequency: 3,
        idleThreshold: 5,
        launchAtLogin: false
    )
}
