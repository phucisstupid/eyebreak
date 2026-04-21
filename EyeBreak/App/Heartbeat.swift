import Foundation

protocol HeartbeatTimer: AnyObject {
    func invalidate()
}

extension Timer: HeartbeatTimer {}

final class Heartbeat {
    var onTick: ((TimeInterval) -> Void)?

    private let interval: TimeInterval
    private var timer: HeartbeatTimer?
    private var lastTickUptime: TimeInterval?

    private let uptimeProvider: () -> TimeInterval
    private let scheduleTimer: (TimeInterval, @escaping () -> Void) -> HeartbeatTimer

    init(
        interval: TimeInterval = 1,
        uptimeProvider: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        scheduleTimer: @escaping (TimeInterval, @escaping () -> Void) -> HeartbeatTimer = { interval, block in
            let timer = Timer(timeInterval: interval, repeats: true) { _ in block() }
            RunLoop.main.add(timer, forMode: .common)
            return timer
        }
    ) {
        self.interval = interval
        self.uptimeProvider = uptimeProvider
        self.scheduleTimer = scheduleTimer
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastTickUptime = uptimeProvider()
        timer = scheduleTimer(interval) { [weak self] in
            guard let self else {
                return
            }

            let currentUptime = self.uptimeProvider()
            let previousUptime = self.lastTickUptime ?? currentUptime
            self.lastTickUptime = currentUptime
            self.onTick?(max(currentUptime - previousUptime, 0))
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastTickUptime = nil
    }

    deinit {
        stop()
    }
}
