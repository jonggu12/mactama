import CoreGraphics
import Foundation

enum Constants {
    static let petStateStorageKey = "mactama.pet-state"
    static let maxEventLogCount = 3
    static let powerPollInterval: TimeInterval = 5
    static let rhythmTickInterval: TimeInterval = 60
    static let eventDeduplicationWindow: TimeInterval = 2
    static let wakeDisplayDuration: TimeInterval = 1
    static let lowBatteryThreshold = 20
    static let criticalBatteryThreshold = 10
    static let popoverSize = CGSize(width: 280, height: 460)
}
