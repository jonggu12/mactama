import Foundation

enum Tendency: String, Codable, CaseIterable {
    case cozy
    case overwork
    case mischief

    var hintText: String {
        switch self {
        case .cozy:
            return "집냥이형 분석 중"
        case .overwork:
            return "야근냥이형 분석 중"
        case .mischief:
            return "장난냥이형 분석 중"
        }
    }
}

enum TendencyAnalysisPhase: String, Codable {
    case analyzing
    case hinted
    case locked
}

enum SignalType: String, Codable, CaseIterable {
    case sleepRegular = "sleep_regular"
    case chargeEarly = "charge_early"
    case daytimeUse = "daytime_use"
    case lateNight = "late_night"
    case cpuHot = "cpu_hot"
    case sleepShort = "sleep_short"
    case batteryDrain = "battery_drain"
    case irregular = "irregular"
    case slap

    var tendency: Tendency {
        switch self {
        case .sleepRegular, .chargeEarly, .daytimeUse:
            return .cozy
        case .lateNight, .cpuHot, .sleepShort:
            return .overwork
        case .batteryDrain, .irregular, .slap:
            return .mischief
        }
    }

    var basePoints: Double {
        switch self {
        case .sleepRegular, .lateNight, .batteryDrain:
            return 3
        case .chargeEarly, .cpuHot, .irregular, .slap:
            return 2
        case .daytimeUse, .sleepShort:
            return 1
        }
    }
}

struct TendencySignal: Codable, Identifiable, Equatable {
    let id: UUID
    let type: SignalType
    let tendency: Tendency
    let points: Double
    let timestamp: Date

    init(id: UUID = UUID(), type: SignalType, timestamp: Date) {
        self.id = id
        self.type = type
        self.tendency = type.tendency
        self.points = type.basePoints
        self.timestamp = timestamp
    }
}

struct TendencyState: Codable, Equatable {
    var phase: TendencyAnalysisPhase
    var hintedTendency: Tendency?
    var lockedTendency: Tendency?
    var lastEvaluatedAt: Date?

    static let initial = TendencyState(
        phase: .analyzing,
        hintedTendency: nil,
        lockedTendency: nil,
        lastEvaluatedAt: nil
    )
}
