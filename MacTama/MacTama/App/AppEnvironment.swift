import Combine
import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var petState: PetState

    private let store: UserDefaultsPetStateStore
    private let powerMonitor: PowerMonitor
    private let sleepWakeMonitor: SleepWakeMonitor
    private var wakeResetTask: Task<Void, Never>?
    private var rhythmTimer: Timer?

    init(
        store: UserDefaultsPetStateStore,
        powerMonitor: PowerMonitor,
        sleepWakeMonitor: SleepWakeMonitor
    ) {
        self.store = store
        self.powerMonitor = powerMonitor
        self.sleepWakeMonitor = sleepWakeMonitor
        self.petState = store.load() ?? .initial
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
        wakeResetTask?.cancel()
        rhythmTimer?.invalidate()
        rhythmTimer = nil
        powerMonitor.stop()
        sleepWakeMonitor.stop()
        persist()
    }

    private func restore() {
        if let storedState = store.load() {
            let now = Date()
            let elapsed = now.timeIntervalSince(storedState.lastUpdatedAt)
            petState = PetStateReducer.applyElapsedTime(to: storedState, elapsed: elapsed)
            petState.lastUpdatedAt = now
        } else {
            petState = .initial
            petState.lastUpdatedAt = Date()
        }
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
        wakeResetTask?.cancel()
        petState = PetStateReducer.reduce(state: petState, event: event)
        persist()

        if event == .wakeDetected {
            scheduleWakeReset()
        }
    }

    private func persist() {
        store.save(petState)
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
        let elapsed = now.timeIntervalSince(petState.lastUpdatedAt)
        petState = PetStateReducer.applyElapsedTime(to: petState, elapsed: elapsed)
        petState.lastUpdatedAt = now
        PetStateReducer.refreshDisplayMode(&petState)
        persist()
    }

    private func scheduleWakeReset() {
        wakeResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Constants.wakeDisplayDuration))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.petState.displayMode == .waking else { return }
                self.petState.displayMode = self.petState.isCharging ? .charging : .awake
                self.petState.lastUpdatedAt = Date()
                PetStateReducer.refreshDisplayMode(&self.petState)
                self.persist()
            }
        }
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
