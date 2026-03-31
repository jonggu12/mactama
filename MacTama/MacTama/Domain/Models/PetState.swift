import Foundation

enum PetDisplayMode: String, Codable {
    case awake
    case charging
    case sleeping
    case waking
}

struct PetEventLogEntry: Codable, Identifiable {
    let id: UUID
    let event: PetEvent
    let occurredAt: Date
}

struct PetState: Codable {
    var displayMode: PetDisplayMode
    var isCharging: Bool
    var lastUpdatedAt: Date
    var recentEvents: [PetEventLogEntry]

    static let initial = PetState(
        displayMode: .awake,
        isCharging: false,
        lastUpdatedAt: Date(),
        recentEvents: []
    )
}

extension PetState {
    var menuBarTitle: String {
        switch displayMode {
        case .awake:
            return "😺"
        case .charging:
            return "⚡😺"
        case .sleeping:
            return "😴"
        case .waking:
            return "☀️😺"
        }
    }

    var statusLabel: String {
        switch displayMode {
        case .awake:
            return "깨어 있음"
        case .charging:
            return "충전 중"
        case .sleeping:
            return "잠자는 중"
        case .waking:
            return "방금 깨어남"
        }
    }

    var powerDescription: String {
        switch displayMode {
        case .charging:
            return "전원 연결됨"
        case .sleeping:
            return "맥북이 잠들어 있어요"
        case .waking:
            return isCharging ? "전원 연결 상태로 복귀 중" : "사용 상태로 복귀 중"
        case .awake:
            return isCharging ? "전원 연결됨" : "배터리 사용 중"
        }
    }

    var tooltipText: String {
        "MacTama • \(statusLabel)"
    }

    var mostRecentEvent: PetEventLogEntry? {
        recentEvents.first
    }
}
