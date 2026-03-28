import CoreGraphics
import Foundation

struct SystemIdleTimeProvider: IdleTimeProviding {
    static let monitoredEventType = CGEventType(rawValue: UInt32.max) ?? .null

    func currentIdleTime() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: Self.monitoredEventType
        )
    }
}
