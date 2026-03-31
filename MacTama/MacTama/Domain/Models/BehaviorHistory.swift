import Foundation

struct BehaviorHistory: Codable, Equatable {
    var currentDay: BehaviorDaySnapshot
    var recentDays: [BehaviorDaySnapshot]
    var signalLog: [TendencySignal]
    var tendencyState: TendencyState
    var lastUpdatedAt: Date

    static func initial(now: Date = Date(), calendar: Calendar = .current) -> BehaviorHistory {
        let day = BehaviorDaySnapshot(dayStart: now, calendar: calendar)
        return BehaviorHistory(
            currentDay: day,
            recentDays: [],
            signalLog: [],
            tendencyState: .initial,
            lastUpdatedAt: now
        )
    }
}

extension BehaviorHistory {
    mutating func rollCurrentDayIfNeeded(now: Date, calendar: Calendar = .current) {
        let currentDayKey = BehaviorDaySnapshot.dayKey(for: now, calendar: calendar)
        guard currentDay.id != currentDayKey else {
            lastUpdatedAt = now
            return
        }

        if !recentDays.contains(where: { $0.id == currentDay.id }) {
            recentDays.insert(currentDay, at: 0)
        }

        recentDays = Array(recentDays.prefix(Constants.behaviorHistoryRetentionDays))
        currentDay = BehaviorDaySnapshot(dayStart: now, calendar: calendar)
        lastUpdatedAt = now
    }

    mutating func pruneOldSignals(now: Date, calendar: Calendar = .current) {
        let cutoffDate = calendar.date(
            byAdding: .day,
            value: -Constants.tendencySignalRetentionDays,
            to: now
        ) ?? now

        signalLog.removeAll { $0.timestamp < cutoffDate }
        recentDays.removeAll { $0.dayStart < cutoffDate }
    }

    mutating func recordChargingSession(batteryPercentage: Int?) {
        currentDay.chargingSessions += 1
        if let batteryPercentage, batteryPercentage >= 40 {
            currentDay.earlyChargeCount += 1
        }
    }

    mutating func recordLowBatteryHit(batteryPercentage: Int?) {
        currentDay.lowBatteryHits += 1
        if let batteryPercentage, batteryPercentage <= Constants.criticalBatteryThreshold {
            currentDay.criticalBatteryHits += 1
        }
    }
}
