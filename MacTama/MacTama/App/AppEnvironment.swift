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
}
