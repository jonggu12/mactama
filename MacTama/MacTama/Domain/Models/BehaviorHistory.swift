import Foundation

struct BehaviorHistory: Codable, Equatable {
    var currentDay: BehaviorDaySnapshot
    var recentDays: [BehaviorDaySnapshot]
    var signalLog: [TendencySignal]
    var tendencyState: TendencyState
    var currentCPUHotStreakSeconds: Int
    var lastChargingDisconnectedAt: Date?
    var lastUpdatedAt: Date

    static func initial(now: Date = Date(), calendar: Calendar = .current) -> BehaviorHistory {
        let day = BehaviorDaySnapshot(dayStart: now, calendar: calendar)
        return BehaviorHistory(
            currentDay: day,
            recentDays: [],
            signalLog: [],
            tendencyState: .initial,
            currentCPUHotStreakSeconds: 0,
            lastChargingDisconnectedAt: nil,
            lastUpdatedAt: now
        )
    }
}

extension BehaviorHistory {
    mutating func rollCurrentDayIfNeeded(
        now: Date,
        calendar: Calendar = .current
    ) -> BehaviorDaySnapshot? {
        let currentDayKey = BehaviorDaySnapshot.dayKey(for: now, calendar: calendar)
        guard currentDay.id != currentDayKey else {
            lastUpdatedAt = now
            return nil
        }

        let finishedDay = currentDay

        if !recentDays.contains(where: { $0.id == currentDay.id }) {
            recentDays.insert(currentDay, at: 0)
        }

        recentDays = Array(recentDays.prefix(Constants.behaviorHistoryRetentionDays))
        currentDay = BehaviorDaySnapshot(dayStart: now, calendar: calendar)
        lastUpdatedAt = now
        return finishedDay
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

    @discardableResult
    mutating func recordChargingSession(batteryPercentage: Int?, now: Date) -> Bool {
        if let lastChargingDisconnectedAt,
           now.timeIntervalSince(lastChargingDisconnectedAt) < Constants.chargingReconnectDebounceWindow {
            return false
        }

        currentDay.chargingSessions += 1
        if let batteryPercentage, batteryPercentage >= 40 {
            currentDay.earlyChargeCount += 1
        }
        return true
    }

    mutating func recordChargingStopped(at date: Date) {
        lastChargingDisconnectedAt = date
    }

    mutating func recordLowBatteryHit(batteryPercentage: Int?) {
        currentDay.lowBatteryHits += 1
        if let batteryPercentage, batteryPercentage <= Constants.criticalBatteryThreshold {
            currentDay.criticalBatteryHits += 1
        }
    }

    mutating func recordUsageMinute(at date: Date, displayMode: PetDisplayMode, calendar: Calendar = .current) {
        if displayMode == .sleeping {
            currentDay.totalSleepMinutes += 1
            return
        }

        currentDay.totalAwakeMinutes += 1

        let hour = calendar.component(.hour, from: date)
        if (0...3).contains(hour) {
            currentDay.lateNightUsageMinutes += 1
        } else if (9...21).contains(hour) {
            currentDay.daytimeUsageMinutes += 1
        }
    }

    mutating func appendSignals(_ signals: [TendencySignal]) {
        signalLog.append(contentsOf: signals)
    }

    mutating func recordCPULoadSample(isHot: Bool, interval: TimeInterval) {
        let intervalSeconds = max(1, Int(interval.rounded()))

        guard isHot else {
            currentCPUHotStreakSeconds = 0
            return
        }

        let previousStreak = currentCPUHotStreakSeconds
        currentCPUHotStreakSeconds += intervalSeconds

        if previousStreak < Int(Constants.cpuHotSustainedDuration),
           currentCPUHotStreakSeconds >= Int(Constants.cpuHotSustainedDuration) {
            currentDay.cpuHotHits += 1
        }
    }
}
