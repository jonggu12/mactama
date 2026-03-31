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
        syncCurrentPowerState()
        handle(.appLaunched)

        powerMonitor.start { [weak self] isCharging in
            Task { @MainActor in
                self?.handle(isCharging ? .chargingStarted : .chargingStopped)
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
        powerMonitor.stop()
        sleepWakeMonitor.stop()
        persist()
    }

    private func restore() {
        if let storedState = store.load() {
            petState = storedState
        } else {
            petState = .initial
        }

        petState.lastUpdatedAt = Date()
        persist()
    }

    private func syncCurrentPowerState() {
        let isCharging = powerMonitor.currentPowerState()
        petState.isCharging = isCharging

        if petState.displayMode != .sleeping {
            petState.displayMode = isCharging ? .charging : .awake
        }

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

    private func scheduleWakeReset() {
        wakeResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Constants.wakeDisplayDuration))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.petState.displayMode == .waking else { return }
                self.petState.displayMode = self.petState.isCharging ? .charging : .awake
                self.petState.lastUpdatedAt = Date()
                self.persist()
            }
        }
    }
}
