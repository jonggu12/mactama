import AppKit

final class SleepWakeMonitor {
    private var willSleepObserver: NSObjectProtocol?
    private var didWakeObserver: NSObjectProtocol?

    func start(willSleep: @escaping () -> Void, didWake: @escaping () -> Void) {
        let center = NSWorkspace.shared.notificationCenter

        willSleepObserver = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            willSleep()
        }

        didWakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            didWake()
        }
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter

        if let willSleepObserver {
            center.removeObserver(willSleepObserver)
        }

        if let didWakeObserver {
            center.removeObserver(didWakeObserver)
        }

        self.willSleepObserver = nil
        self.didWakeObserver = nil
    }
}
