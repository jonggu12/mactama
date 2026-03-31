import Foundation
import IOKit.ps

struct PowerSnapshot {
    let isCharging: Bool
    let batteryPercentage: Int?

    var isLowBattery: Bool {
        guard let batteryPercentage else { return false }
        return batteryPercentage <= Constants.lowBatteryThreshold
    }
}

final class PowerMonitor {
    private var timer: Timer?
    private var handler: ((PowerSnapshot) -> Void)?
    private var lastSnapshot: PowerSnapshot?

    func start(handler: @escaping (PowerSnapshot) -> Void) {
        self.handler = handler

        let snapshot = currentSnapshot()
        lastSnapshot = snapshot
        handler(snapshot)

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

    func currentSnapshot() -> PowerSnapshot {
        Self.readSnapshot()
    }

    private func poll() {
        let snapshot = currentSnapshot()
        guard shouldPublish(snapshot) else { return }

        lastSnapshot = snapshot
        handler?(snapshot)
    }

    private func shouldPublish(_ snapshot: PowerSnapshot) -> Bool {
        guard let lastSnapshot else { return true }

        return snapshot.isCharging != lastSnapshot.isCharging
            || snapshot.isLowBattery != lastSnapshot.isLowBattery
    }

    private static func readSnapshot() -> PowerSnapshot {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array
        let isCharging = isOnACPower(info)
        let batteryPercentage = readBatteryPercentage(info: info, sources: sources)

        return PowerSnapshot(isCharging: isCharging, batteryPercentage: batteryPercentage)
    }

    private static func isOnACPower(_ info: CFTypeRef) -> Bool {
        guard let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else {
            return false
        }

        return source == kIOPSACPowerValue as CFString
    }

    private static func readBatteryPercentage(info: CFTypeRef, sources: [Any]) -> Int? {
        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(info, source as CFTypeRef)?
                    .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int
            else {
                continue
            }

            return currentCapacity
        }

        return nil
    }
}
