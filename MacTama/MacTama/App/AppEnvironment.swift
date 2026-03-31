import Combine
import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var petState: PetState
    @Published private(set) var behaviorHistory: BehaviorHistory

    private let store: UserDefaultsPetStateStore
    private let behaviorHistoryStore: UserDefaultsBehaviorHistoryStore
    private let powerMonitor: PowerMonitor
    private let cpuLoadMonitor: CPULoadMonitor
    private let sleepWakeMonitor: SleepWakeMonitor
    private var rhythmTimer: Timer?

    init(
        store: UserDefaultsPetStateStore,
        behaviorHistoryStore: UserDefaultsBehaviorHistoryStore,
        powerMonitor: PowerMonitor,
        cpuLoadMonitor: CPULoadMonitor,
        sleepWakeMonitor: SleepWakeMonitor
    ) {
        self.store = store
        self.behaviorHistoryStore = behaviorHistoryStore
        self.powerMonitor = powerMonitor
        self.cpuLoadMonitor = cpuLoadMonitor
        self.sleepWakeMonitor = sleepWakeMonitor
        self.petState = store.load() ?? .initial
        self.behaviorHistory = behaviorHistoryStore.load() ?? .initial()
    }

    func start() {
        restore()
        syncCurrentPowerSnapshot()
        handle(.appLaunched)
        startRhythmTimer()

        powerMonitor.start { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot: snapshot)
            }
        }

        cpuLoadMonitor.start { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot: snapshot)
            }
        }

        sleepWakeMonitor.start(
            willSleep: { [weak self] in
                Task { @MainActor in
                    self?.handle(.sleepEntered)
                }
            },
            didWake: { [weak self] in
                Task { @MainActor in
                    self?.handle(.wakeDetected)
                }
            }
        )
    }

    func stop() {
        rhythmTimer?.invalidate()
        rhythmTimer = nil
        powerMonitor.stop()
        cpuLoadMonitor.stop()
        sleepWakeMonitor.stop()
        persist()
    }

    var debugBehaviorSummary: [String] {
        let day = behaviorHistory.currentDay
        return [
            "오늘 버킷: \(day.id)",
            "awake \(day.totalAwakeMinutes)분 · sleep \(day.totalSleepMinutes)분",
            "daytime \(day.daytimeUsageMinutes)분 · lateNight \(day.lateNightUsageMinutes)분",
            "충전 \(day.chargingSessions)회 · 저배터리 \(day.lowBatteryHits)회 · CPU hot \(day.cpuHotHits)회",
            "최근 일수 \(behaviorHistory.recentDays.count) · 신호 \(behaviorHistory.signalLog.count)개",
            "충전 재연결 기준 \(Int(Constants.chargingReconnectDebounceWindow))초 · CPU \(Int(Constants.cpuHotThresholdPercent))%/\(Int(Constants.cpuHotSustainedDuration / 60))분"
        ]
    }

    private func restore() {
        let now = Date()

        if let storedState = store.load() {
            let elapsed = now.timeIntervalSince(storedState.lastUpdatedAt)
            petState = PetStateReducer.applyElapsedTime(to: storedState, elapsed: elapsed)
            petState.lastUpdatedAt = now
        } else {
            petState = .initial
            petState.lastUpdatedAt = now
        }

        if let storedHistory = behaviorHistoryStore.load() {
            behaviorHistory = storedHistory
        } else {
            behaviorHistory = .initial(now: now)
        }
        finalizeBehaviorDayIfNeeded(now: now)
        behaviorHistory.pruneOldSignals(now: now)
        persist()
    }

    private func syncCurrentPowerSnapshot() {
        let snapshot = powerMonitor.currentSnapshot()
        petState.isCharging = snapshot.isCharging
        petState.isLowBattery = snapshot.isLowBattery
        petState.batteryPercentage = snapshot.batteryPercentage
        if petState.displayMode == .sleeping {
            petState.displayMode = .awake
        }
        PetStateReducer.refreshDisplayMode(&petState)
        persist()
    }

    private func handle(_ event: PetEvent) {
        let now = Date()
        finalizeBehaviorDayIfNeeded(now: now)

        switch event {
        case .chargingStarted:
            _ = behaviorHistory.recordChargingSession(
                batteryPercentage: petState.batteryPercentage,
                now: now
            )
        case .chargingStopped:
            behaviorHistory.recordChargingStopped(at: now)
        case .lowBatteryDetected:
            behaviorHistory.recordLowBatteryHit(batteryPercentage: petState.batteryPercentage)
        default:
            break
        }

        petState = PetStateReducer.reduce(state: petState, event: event)
        persist()
    }

    private func persist() {
        behaviorHistory.pruneOldSignals(now: Date())
        store.save(petState)
        behaviorHistoryStore.save(behaviorHistory)
    }

    private func apply(snapshot: PowerSnapshot) {
        let previousCharging = petState.isCharging
        let previousLowBattery = petState.isLowBattery

        petState.isCharging = snapshot.isCharging
        petState.isLowBattery = snapshot.isLowBattery
        petState.batteryPercentage = snapshot.batteryPercentage

        if previousCharging != snapshot.isCharging {
            handle(snapshot.isCharging ? .chargingStarted : .chargingStopped)
            return
        }

        if previousLowBattery != snapshot.isLowBattery {
            handle(snapshot.isLowBattery ? .lowBatteryDetected : .batteryRecovered)
            return
        }

        PetStateReducer.refreshDisplayMode(&petState)
        persist()
    }

    private func apply(snapshot: CPULoadSnapshot) {
        behaviorHistory.recordCPULoadSample(isHot: snapshot.isHot, interval: snapshot.sampleInterval)
        behaviorHistory.lastUpdatedAt = Date()
        persist()
    }

    private func startRhythmTimer() {
        let timer = Timer.scheduledTimer(
            timeInterval: Constants.rhythmTickInterval,
            target: self,
            selector: #selector(handleRhythmTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        rhythmTimer = timer
    }

    @objc
    private func handleRhythmTick() {
        advanceRhythm()
    }

    private func advanceRhythm() {
        let now = Date()
        let previousUpdatedAt = petState.lastUpdatedAt
        let elapsed = now.timeIntervalSince(previousUpdatedAt)

        recordBehaviorElapsed(from: previousUpdatedAt, to: now, displayMode: petState.displayMode)

        petState = PetStateReducer.applyElapsedTime(to: petState, elapsed: elapsed)
        petState.lastUpdatedAt = now
        PetStateReducer.refreshDisplayMode(&petState)
        persist()
    }

    private func finalizeBehaviorDayIfNeeded(now: Date) {
        guard let finishedDay = behaviorHistory.rollCurrentDayIfNeeded(now: now) else {
            return
        }

        let signals = TendencySignalDeriver.deriveSignals(from: finishedDay, timestamp: now)
        behaviorHistory.appendSignals(signals)
    }

    private func recordBehaviorElapsed(from start: Date, to end: Date, displayMode: PetDisplayMode) {
        guard end > start else { return }

        let elapsedMinutes = max(1, Int(ceil(end.timeIntervalSince(start) / 60)))
        var cursor = start

        for _ in 0..<elapsedMinutes {
            finalizeBehaviorDayIfNeeded(now: cursor)
            behaviorHistory.recordUsageMinute(at: cursor, displayMode: displayMode)
            cursor = cursor.addingTimeInterval(60)
        }

        finalizeBehaviorDayIfNeeded(now: end)
        behaviorHistory.lastUpdatedAt = end
    }

#if DEBUG
    func debugSimulateLowBattery() {
        petState.isCharging = false
        petState.isLowBattery = true
        petState.batteryPercentage = 18
        handle(.lowBatteryDetected)
    }

    func debugRecoverBattery() {
        petState.isCharging = false
        petState.isLowBattery = false
        petState.batteryPercentage = 55
        petState.rhythm.energy = max(petState.rhythm.energy, 60)
        petState.rhythm.fatigue = min(petState.rhythm.fatigue, 40)
        petState.rhythm.mood = max(petState.rhythm.mood, 55)
        handle(.batteryRecovered)
    }

    func debugForceCriticalFatigue() {
        petState.isCharging = false
        petState.isLowBattery = false
        petState.batteryPercentage = 9
        petState.rhythm.energy = 10
        petState.rhythm.fatigue = 95
        petState.rhythm.mood = 28
        PetStateReducer.refreshDisplayMode(&petState)
        petState.lastUpdatedAt = Date()
        persist()
    }

    func debugResetRhythm() {
        petState.isLowBattery = false
        petState.batteryPercentage = petState.isCharging ? 100 : 72
        petState.rhythm = .initial
        PetStateReducer.refreshDisplayMode(&petState)
        petState.lastUpdatedAt = Date()
        persist()
    }
#endif
}
