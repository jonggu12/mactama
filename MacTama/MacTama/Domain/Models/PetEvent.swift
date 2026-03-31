import Foundation

enum PetEvent: String, Codable {
    case appLaunched
    case chargingStarted
    case chargingStopped
    case lowBatteryDetected
    case batteryRecovered
    case sleepEntered
    case wakeDetected
}

extension PetEvent {
    var title: String {
        switch self {
        case .appLaunched:
            return "앱 실행"
        case .chargingStarted:
            return "충전 시작"
        case .chargingStopped:
            return "충전 종료"
        case .lowBatteryDetected:
            return "저배터리 감지"
        case .batteryRecovered:
            return "배터리 회복"
        case .sleepEntered:
            return "수면 진입"
        case .wakeDetected:
            return "기상 감지"
        }
    }

    var detail: String {
        switch self {
        case .appLaunched:
            return "MacTama를 시작했어요"
        case .chargingStarted:
            return "맥북이 전원을 먹는 중이에요"
        case .chargingStopped:
            return "전원 케이블이 분리됐어요"
        case .lowBatteryDetected:
            return "배터리가 낮아 조금 위태로워 보여요"
        case .batteryRecovered:
            return "배터리가 다시 안정권으로 돌아왔어요"
        case .sleepEntered:
            return "맥북이 잠들었어요"
        case .wakeDetected:
            return "맥북이 다시 깨어났어요"
        }
    }
}
