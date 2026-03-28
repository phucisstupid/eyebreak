import Foundation

enum BreakType: String, Codable, Equatable {
    case short
    case long

    static func next(
        afterCompletedBreakCount completedBreakCount: Int,
        using settings: AppSettings
    ) -> BreakType {
        guard settings.longBreakFrequency > 0 else {
            return .short
        }

        return (completedBreakCount + 1).isMultiple(of: settings.longBreakFrequency)
            ? .long : .short
    }

    func duration(using settings: AppSettings) -> TimeInterval {
        switch self {
        case .short:
            return settings.shortBreakDuration
        case .long:
            return settings.longBreakDuration
        }
    }
}
