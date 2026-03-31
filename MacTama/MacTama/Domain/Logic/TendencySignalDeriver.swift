import Foundation

enum TendencySignalDeriver {
    static func deriveSignals(from snapshot: BehaviorDaySnapshot, timestamp: Date) -> [TendencySignal] {
        var signals: [TendencySignal] = []

        if snapshot.totalSleepMinutes >= 360, snapshot.lateNightUsageMinutes <= 60 {
            signals.append(TendencySignal(type: .sleepRegular, timestamp: timestamp))
        }

        if snapshot.earlyChargeCount > 0 {
            signals.append(TendencySignal(type: .chargeEarly, timestamp: timestamp))
        }

        if snapshot.daytimeUsageMinutes >= max(snapshot.lateNightUsageMinutes, 60) {
            signals.append(TendencySignal(type: .daytimeUse, timestamp: timestamp))
        }

        if snapshot.lateNightUsageMinutes >= 30 {
            signals.append(TendencySignal(type: .lateNight, timestamp: timestamp))
        }

        if snapshot.cpuHotHits > 0 {
            signals.append(TendencySignal(type: .cpuHot, timestamp: timestamp))
        }

        if snapshot.totalSleepMinutes > 0, snapshot.totalSleepMinutes <= 240 {
            signals.append(TendencySignal(type: .sleepShort, timestamp: timestamp))
        }

        if snapshot.lowBatteryHits > 0 {
            signals.append(TendencySignal(type: .batteryDrain, timestamp: timestamp))
        }

        if snapshot.irregularityHits > 0 {
            signals.append(TendencySignal(type: .irregular, timestamp: timestamp))
        }

        if snapshot.slapCount > 0 {
            signals.append(TendencySignal(type: .slap, timestamp: timestamp))
        }

        return signals
    }
}
