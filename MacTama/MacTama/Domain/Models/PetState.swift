import Foundation

enum PetDisplayMode: String, Codable {
    case awake
    case charging
    case lowEnergy
    case critical
    case sleeping
}

struct PetRhythm: Codable {
    var energy: Int
    var mood: Int
    var fatigue: Int

    static let initial = PetRhythm(energy: 78, mood: 72, fatigue: 22)
}

struct PetEventLogEntry: Codable, Identifiable {
    let id: UUID
    let event: PetEvent
    let occurredAt: Date
}

struct PetState: Codable {
    var displayMode: PetDisplayMode
    var isCharging: Bool
    var isLowBattery: Bool
    var batteryPercentage: Int?
    var rhythm: PetRhythm
    var lastUpdatedAt: Date
    var recentEvents: [PetEventLogEntry]

    static let initial = PetState(
        displayMode: .awake,
        isCharging: false,
        isLowBattery: false,
        batteryPercentage: nil,
        rhythm: .initial,
        lastUpdatedAt: Date(),
        recentEvents: []
    )
}

extension PetState {
    var menuBarTitle: String {
        if isCharging {
            return "🔌😺"
        }

        switch displayMode {
        case .awake:
            return "😺"
        case .charging:
            return "🔌😺"
        case .lowEnergy:
            return "🪫😺"
        case .critical:
            return "😵"
        case .sleeping:
            return "😴"
        }
    }

    var statusLabel: String {
        switch displayMode {
        case .awake:
            return "깨어 있어요"
        case .charging:
            return "충전 중이에요"
        case .lowEnergy:
            return "슬슬 지쳐가요"
        case .critical:
            return "많이 지쳤어요"
        case .sleeping:
            return "잠들었어요"
        }
    }

    var powerDescription: String {
        switch displayMode {
        case .charging:
            if let batteryPercentage, batteryPercentage <= Constants.lowBatteryThreshold {
                return "전원 연결됨 · 배터리 회복 중"
            }
            return "전원 연결됨"
        case .lowEnergy:
            return "배터리로 버티는 중"
        case .critical:
            return "지금은 회복이 필요한 상태예요"
        case .sleeping:
            return "맥북이 잠들어 있어요"
        case .awake:
            return isCharging ? "전원 연결됨" : "배터리 사용 중"
        }
    }

    var stateDescription: String {
        switch displayMode {
        case .charging:
            return "기운을 채우는 중이에요"
        case .lowEnergy:
            return "충전해 주면 좋겠어요"
        case .critical:
            return "지금은 쉬거나 충전이 필요해요"
        case .sleeping:
            return "맥북이 쉬는 동안 같이 잠들었어요"
        case .awake:
            return "조용히 옆에 있어요"
        }
    }

    var traitStatusText: String {
        "성향 분석 중"
    }

    var rhythmSummaryText: String {
        let energyText: String
        if rhythm.energy <= 25 {
            energyText = "에너지가 많이 줄었어요"
        } else if rhythm.energy <= 55 {
            energyText = "기운이 조금 줄었어요"
        } else {
            energyText = "에너지는 안정적이에요"
        }

        let fatigueText: String
        if rhythm.fatigue >= 75 {
            fatigueText = "피곤함이 꽤 쌓였어요"
        } else if rhythm.fatigue >= 45 {
            fatigueText = "살짝 나른한 상태예요"
        } else {
            fatigueText = "컨디션이 무난해 보여요"
        }

        return "\(energyText) · \(fatigueText)"
    }

    var tooltipText: String {
        "MacTama • \(statusLabel)"
    }

    var mostRecentEvent: PetEventLogEntry? {
        recentEvents.first
    }
}
