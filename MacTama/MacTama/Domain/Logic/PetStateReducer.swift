import Foundation

enum PetStateReducer {
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
            if nextState.displayMode != .sleeping {
                nextState.displayMode = .charging
            }

        case .chargingStopped:
            nextState.isCharging = false
            if nextState.displayMode != .sleeping {
                nextState.displayMode = .awake
            }

        case .sleepEntered:
            nextState.displayMode = .sleeping

        case .wakeDetected:
            nextState.displayMode = .waking
        }

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
}
