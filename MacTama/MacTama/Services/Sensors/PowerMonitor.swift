import Foundation
import IOKit.ps

final class PowerMonitor {
    private var timer: Timer?
    private var handler: ((Bool) -> Void)?
    private var lastKnownIsCharging: Bool?

    func start(handler: @escaping (Bool) -> Void) {
        self.handler = handler

        let currentState = currentPowerState()
        lastKnownIsCharging = currentState
        handler(currentState)

        let timer = Timer.scheduledTimer(withTimeInterval: Constants.powerPollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func currentPowerState() -> Bool {
        Self.isOnACPower()
    }

    private func poll() {
        let currentState = currentPowerState()
        guard currentState != lastKnownIsCharging else { return }

        lastKnownIsCharging = currentState
        handler?(currentState)
    }

    private static func isOnACPower() -> Bool {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()

        guard let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else {
            return false
        }

        return source == kIOPSACPowerValue as CFString
    }
}
