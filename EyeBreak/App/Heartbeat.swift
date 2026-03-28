import Foundation

final class Heartbeat {
    var onTick: ((TimeInterval) -> Void)?

    private let interval: TimeInterval
    private var timer: Timer?
    private var lastTickUptime: TimeInterval?

    init(interval: TimeInterval = 1) {
        self.interval = interval
    }

    func start() {
        guard timer == nil else {
            return
        }

        lastTickUptime = ProcessInfo.processInfo.systemUptime
        let interval = interval
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }

            let currentUptime = ProcessInfo.processInfo.systemUptime
            let previousUptime = lastTickUptime ?? currentUptime
            lastTickUptime = currentUptime
            onTick?(max(currentUptime - previousUptime, 0))
        }

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
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
