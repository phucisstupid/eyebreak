import CoreGraphics
import XCTest

@testable import EyeBreak

final class SystemIdleTimeProviderTests: XCTestCase {
    func test_tracksAnyInputEventTypeRatherThanNullEventType() {
        XCTAssertEqual(SystemIdleTimeProvider.monitoredEventType, CGEventType(rawValue: UInt32.max))
        XCTAssertNotEqual(SystemIdleTimeProvider.monitoredEventType, CGEventType.null)
    }
}
