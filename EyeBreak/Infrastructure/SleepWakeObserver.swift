import AppKit
import Foundation

final class SleepWakeObserver {
    var onSleep: (() -> Void)?
    var onWake: (() -> Void)?

    private let notificationCenter: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(workspace: NSWorkspace = .shared) {
        notificationCenter = workspace.notificationCenter
    }

    func start() {
        guard observers.isEmpty else {
            return
        }

        let onSleep = self.onSleep
        let onWake = self.onWake
        observers = []
        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { _ in
                onSleep?()
            }
        )
        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                onWake?()
            }
        )
    }

    func stop() {
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
    }

    deinit {
        stop()
    }
}
