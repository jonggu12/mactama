import Foundation

enum PetStateReducer {
    static func applyElapsedTime(to state: PetState, elapsed: TimeInterval) -> PetState {
        guard elapsed > 0 else { return state }

        var nextState = state
        let minutes = max(1, Int(elapsed / 60))

        if nextState.displayMode == .sleeping {
            nextState.rhythm.fatigue -= minutes / 3
            nextState.rhythm.mood += max(1, minutes / 12)

            if nextState.isCharging {
                nextState.rhythm.energy += max(1, minutes / 2)
            } else {
                nextState.rhythm.energy -= minutes / 20
            }
        } else {
            nextState.rhythm.energy -= max(1, minutes / 6)
            nextState.rhythm.mood -= max(1, minutes / 14)
            nextState.rhythm.fatigue += max(1, minutes / 8)

            if nextState.isCharging {
                nextState.rhythm.energy += max(1, minutes / 3)
                nextState.rhythm.mood += max(0, minutes / 18)
            }
        }

        clampRhythm(&nextState)

        if nextState.displayMode != .sleeping && nextState.displayMode != .waking {
            refreshDisplayMode(&nextState)
        }

        nextState.lastUpdatedAt = state.lastUpdatedAt.addingTimeInterval(elapsed)
        return nextState
    }

    static func reduce(state: PetState, event: PetEvent) -> PetState {
        var nextState = state
        let now = Date()
        nextState.lastUpdatedAt = now

        switch event {
        case .appLaunched:
            if nextState.displayMode != .sleeping {
                nextState.displayMode = nextState.isCharging ? .charging : .awake
            }

        case .chargingStarted:
            nextState.isCharging = true
            nextState.rhythm.energy += 12
            nextState.rhythm.mood += 4
            if nextState.displayMode != .sleeping {
                refreshDisplayMode(&nextState)
            }

        case .chargingStopped:
            nextState.isCharging = false
            if nextState.displayMode != .sleeping {
                refreshDisplayMode(&nextState)
            }

        case .lowBatteryDetected:
            nextState.isLowBattery = true
            nextState.rhythm.energy = min(nextState.rhythm.energy, 18)
            nextState.rhythm.mood -= 6
            refreshDisplayMode(&nextState)

        case .batteryRecovered:
            nextState.isLowBattery = false
            refreshDisplayMode(&nextState)

        case .sleepEntered:
            nextState.displayMode = .sleeping

        case .wakeDetected:
            nextState.rhythm.mood += 3
            nextState.displayMode = .waking
        }

        clampRhythm(&nextState)

        if shouldAppendEvent(event, to: state.recentEvents, occurredAt: now) {
            let entry = PetEventLogEntry(id: UUID(), event: event, occurredAt: now)
            nextState.recentEvents.insert(entry, at: 0)
            nextState.recentEvents = Array(nextState.recentEvents.prefix(Constants.maxEventLogCount))
        }

        return nextState
    }

    private static func shouldAppendEvent(
        _ event: PetEvent,
        to recentEvents: [PetEventLogEntry],
        occurredAt now: Date
    ) -> Bool {
        guard let lastEvent = recentEvents.first else {
            return true
        }

        let isDuplicateEvent = lastEvent.event == event
        let isWithinWindow = now.timeIntervalSince(lastEvent.occurredAt) < Constants.eventDeduplicationWindow

        return !(isDuplicateEvent && isWithinWindow)
    }

    static func refreshDisplayMode(_ state: inout PetState) {
        guard state.displayMode != .sleeping && state.displayMode != .waking else {
            return
        }

        if state.rhythm.energy <= 8 || state.rhythm.fatigue >= 92 || (state.isLowBattery && !state.isCharging) {
            state.displayMode = .critical
        } else if state.isCharging {
            state.displayMode = .charging
        } else if state.isLowBattery || state.rhythm.energy <= 35 || state.rhythm.fatigue >= 72 {
            state.displayMode = .lowEnergy
        } else {
            state.displayMode = .awake
        }
    }

    private static func clampRhythm(_ state: inout PetState) {
        state.rhythm.energy = state.rhythm.energy.clamped(to: 0...100)
        state.rhythm.mood = state.rhythm.mood.clamped(to: 0...100)
        state.rhythm.fatigue = state.rhythm.fatigue.clamped(to: 0...100)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
