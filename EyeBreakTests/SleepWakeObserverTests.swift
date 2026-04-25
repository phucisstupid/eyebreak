import AppKit
import XCTest
@testable import EyeBreak

final class SleepWakeObserverTests: XCTestCase {
    class MockWorkspace: NSWorkspace {
        let mockNotificationCenter = NotificationCenter()
        override var notificationCenter: NotificationCenter { mockNotificationCenter }
    }

    func test_start_observesWillSleepAndDidWakeNotifications() {
        let workspace = MockWorkspace()
        let sut = SleepWakeObserver(workspace: workspace)

        var sleepCallCount = 0
        var wakeCallCount = 0

        sut.onSleep = { sleepCallCount += 1 }
        sut.onWake = { wakeCallCount += 1 }

        sut.start()

        XCTAssertEqual(sleepCallCount, 0)
        XCTAssertEqual(wakeCallCount, 0)

        workspace.mockNotificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        XCTAssertEqual(sleepCallCount, 1)
        XCTAssertEqual(wakeCallCount, 0)

        workspace.mockNotificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(sleepCallCount, 1)
        XCTAssertEqual(wakeCallCount, 1)
    }

    func test_start_multipleTimes_doesNotDuplicateObservers() {
        let workspace = MockWorkspace()
        let sut = SleepWakeObserver(workspace: workspace)

        var sleepCallCount = 0
        sut.onSleep = { sleepCallCount += 1 }

        sut.start()
        sut.start()
        sut.start()

        workspace.mockNotificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        XCTAssertEqual(sleepCallCount, 1, "Calling start multiple times should not add duplicate observers.")
    }

    func test_stop_removesObservers() {
        let workspace = MockWorkspace()
        let sut = SleepWakeObserver(workspace: workspace)

        var wakeCallCount = 0
        sut.onWake = { wakeCallCount += 1 }

        sut.start()
        sut.stop()

        workspace.mockNotificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(wakeCallCount, 0)
    }

    func test_deinit_stopsObserving() {
        let workspace = MockWorkspace()
        var wakeCallCount = 0

        var sut: SleepWakeObserver? = SleepWakeObserver(workspace: workspace)
        sut?.onWake = { wakeCallCount += 1 }
        sut?.start()

        sut = nil

        workspace.mockNotificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(wakeCallCount, 0)
    }
}
