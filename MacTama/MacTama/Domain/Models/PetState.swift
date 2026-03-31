import Foundation

enum PetDisplayMode: String, Codable {
    case awake
    case charging
    case lowEnergy
    case critical
    case sleeping
    case waking
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
        case .lowEnergy:
            return "기운 없음"
        case .critical:
            return "위태로움"
        case .sleeping:
            return "잠자는 중"
        case .waking:
            return "방금 깨어남"
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
        case .waking:
            return isCharging ? "전원 연결 상태로 복귀 중" : "사용 상태로 복귀 중"
        case .awake:
            return isCharging ? "전원 연결됨" : "배터리 사용 중"
        }
    }

    var stateDescription: String {
        switch displayMode {
        case .charging:
            if rhythm.fatigue >= 70 {
                return "전원을 먹으며 천천히 기운을 회복하는 중이에요."
            }
            return "안정적으로 충전하면서 여유를 되찾고 있어요."
        case .lowEnergy:
            if isLowBattery {
                return "배터리가 낮아서 조심조심 버티는 중이에요."
            }
            return "기운이 조금 줄어서 조용히 버티는 중이에요."
        case .critical:
            if isLowBattery {
                return "배터리가 많이 낮아 보여요. 곧 충전이 필요해요."
            }
            return "많이 지쳐 보여요. 조금 쉬면 괜찮아질 거예요."
        case .sleeping:
            return "지금은 조용히 쉬는 시간이예요."
        case .waking:
            return "막 잠에서 깨어나는 중이에요."
        case .awake:
            if rhythm.fatigue >= 65 {
                return "조금 지친 표정이지만 아직 버틸 만해 보여요."
            }
            if rhythm.mood >= 75 {
                return "기분 좋게 깨어 있는 상태예요."
            }
            return "조용히 대기하면서 맥북과 같이 시간을 보내고 있어요."
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
