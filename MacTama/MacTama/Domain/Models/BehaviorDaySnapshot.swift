import Foundation

struct BehaviorDaySnapshot: Codable, Equatable, Identifiable {
    let id: String
    var dayStart: Date

    var totalAwakeMinutes: Int
    var totalSleepMinutes: Int
    var daytimeUsageMinutes: Int
    var lateNightUsageMinutes: Int

    var chargingSessions: Int
    var earlyChargeCount: Int
    var lowBatteryHits: Int
    var criticalBatteryHits: Int
    var cpuHotMinutes: Int
    var irregularityHits: Int
    var slapCount: Int

    init(dayStart: Date, calendar: Calendar = .current) {
        let normalizedDayStart = calendar.startOfDay(for: dayStart)
        self.id = BehaviorDaySnapshot.dayKey(for: normalizedDayStart, calendar: calendar)
        self.dayStart = normalizedDayStart
        self.totalAwakeMinutes = 0
        self.totalSleepMinutes = 0
        self.daytimeUsageMinutes = 0
        self.lateNightUsageMinutes = 0
        self.chargingSessions = 0
        self.earlyChargeCount = 0
        self.lowBatteryHits = 0
        self.criticalBatteryHits = 0
        self.cpuHotMinutes = 0
        self.irregularityHits = 0
        self.slapCount = 0
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
