import Foundation

enum AppPhase: String, Codable, Equatable {
    case running
    case waitingForIdle
    case paused
    case breakInProgress
}
