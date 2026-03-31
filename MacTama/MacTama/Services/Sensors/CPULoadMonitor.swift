import Darwin.Mach
import Foundation

struct CPULoadSnapshot {
    let overallUsagePercent: Double
    let sampleInterval: TimeInterval

    var isHot: Bool {
        overallUsagePercent >= Constants.cpuHotThresholdPercent
    }
}

final class CPULoadMonitor {
    private struct Sample {
        let user: UInt32
        let system: UInt32
        let idle: UInt32
        let nice: UInt32
        let takenAt: Date
    }

    private var timer: Timer?
    private var handler: ((CPULoadSnapshot) -> Void)?
    private var lastSample: Sample?

    func start(handler: @escaping (CPULoadSnapshot) -> Void) {
        self.handler = handler
        lastSample = Self.readSample()

        let timer = Timer.scheduledTimer(withTimeInterval: Constants.cpuPollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard let currentSample = Self.readSample() else {
            return
        }

        defer { lastSample = currentSample }

        guard let lastSample else {
            return
        }

        let deltaUser = Double(currentSample.user - lastSample.user)
        let deltaSystem = Double(currentSample.system - lastSample.system)
        let deltaIdle = Double(currentSample.idle - lastSample.idle)
        let deltaNice = Double(currentSample.nice - lastSample.nice)
        let deltaTotal = deltaUser + deltaSystem + deltaIdle + deltaNice

        guard deltaTotal > 0 else {
            return
        }

        let active = deltaUser + deltaSystem + deltaNice
        let usage = (active / deltaTotal) * 100
        let interval = currentSample.takenAt.timeIntervalSince(lastSample.takenAt)
        handler?(CPULoadSnapshot(overallUsagePercent: usage, sampleInterval: interval))
    }

    private static func readSample() -> Sample? {
        var cpuInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &cpuInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, integerPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        return Sample(
            user: cpuInfo.cpu_ticks.0,
            system: cpuInfo.cpu_ticks.1,
            idle: cpuInfo.cpu_ticks.2,
            nice: cpuInfo.cpu_ticks.3,
            takenAt: Date()
        )
    }
}
