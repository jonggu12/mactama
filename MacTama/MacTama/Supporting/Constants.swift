import CoreGraphics
import Foundation

enum Constants {
    static let petStateStorageKey = "mactama.pet-state"
    static let maxEventLogCount = 3
    static let powerPollInterval: TimeInterval = 5
    static let eventDeduplicationWindow: TimeInterval = 2
    static let wakeDisplayDuration: TimeInterval = 1
    static let popoverSize = CGSize(width: 240, height: 220)
}
