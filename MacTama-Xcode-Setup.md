# MacTama — Xcode Project Structure & ChatGPT Integration Notes

> 작성일 2026-03-31  
> 대상: MacTama macOS 메뉴바 앱 초기 구조 설계

---

## 1. 목적

이 문서는 두 가지를 정리한다.

- MacTama를 Xcode에서 어떻게 시작하면 좋은지
- Xcode와 ChatGPT를 어떤 방식으로 같이 쓸 수 있는지

핵심 원칙:

- 메뉴바 앱은 가볍고 안정적이어야 한다
- UI, 상태 로직, 센서 입력을 초기에 분리해 둬야 한다
- ChatGPT는 "개발 보조"와 "앱 기능 연동"을 구분해서 생각해야 한다

---

## 2. 권장 개발 환경

- IDE: Xcode
- UI: SwiftUI
- 메뉴바 제어: AppKit
- 상태 관리: `ObservableObject` 또는 `@Observable`
- 저장소: `UserDefaults`
- 센서 입력: `NSWorkspace`, `IOPSCopyPowerSourcesInfo`

MacTama 같은 macOS 메뉴바 앱은 사실상 Xcode로 시작하는 게 가장 자연스럽다.

이유:

- `NSStatusItem`, `NSPopover`, `NSWorkspace` 같은 핵심 기능이 macOS 네이티브 API에 있다
- 코드 서명, notarization, 배포 흐름까지 Xcode가 가장 잘 맞는다
- Electron/Tauri보다 리소스와 메뉴바 통합 측면에서 유리하다

---

## 3. 추천 프로젝트 구조

```text
MacTama/
├─ MacTamaApp.swift
├─ App/
│  ├─ AppDelegate.swift
│  ├─ StatusBarController.swift
│  ├─ PopoverController.swift
│  └─ AppEnvironment.swift
├─ Domain/
│  ├─ Models/
│  │  ├─ PetState.swift
│  │  ├─ PetEvent.swift
│  │  ├─ PetMood.swift
│  │  └─ PowerState.swift
│  ├─ Logic/
│  │  ├─ PetStateReducer.swift
│  │  ├─ MoodResolver.swift
│  │  └─ EventLogger.swift
│  └─ Repositories/
│     └─ PetStateStore.swift
├─ Features/
│  ├─ MenuBar/
│  │  ├─ MenuBarViewModel.swift
│  │  └─ MenuBarIconRenderer.swift
│  ├─ Popover/
│  │  ├─ PopoverView.swift
│  │  ├─ PopoverViewModel.swift
│  │  └─ Components/
│  │     ├─ PetPreviewView.swift
│  │     ├─ StatusRowView.swift
│  │     └─ EventLogView.swift
│  └─ Debug/
│     └─ DebugPanelView.swift
├─ Services/
│  ├─ Sensors/
│  │  ├─ PowerMonitor.swift
│  │  ├─ SleepWakeMonitor.swift
│  │  └─ SensorEventBridge.swift
│  ├─ Persistence/
│  │  └─ UserDefaultsPetStateStore.swift
│  ├─ Animation/
│  │  └─ EmojiAnimationService.swift
│  └─ Analytics/
│     └─ AnalyticsService.swift
├─ Resources/
│  ├─ Assets.xcassets
│  └─ Preview Content/
└─ Supporting/
   ├─ Config.swift
   └─ Constants.swift
```

---

## 4. 폴더 역할

### 4.1 `App/`

앱 시작점과 메뉴바 앱 제어를 담당한다.

- 앱 수명주기
- 상태바 아이템 생성
- 팝오버 열기/닫기
- 전역 의존성 연결

### 4.2 `Domain/`

앱 규칙의 중심이다.

- 펫 상태 모델
- 이벤트 정의
- 상태 계산 규칙
- mood 판별
- 이벤트 로그 적재

중요:

- 여기는 UI를 몰라야 한다
- 가능한 한 macOS API도 직접 몰라야 한다

### 4.3 `Features/`

실제 사용자에게 보이는 UI 레이어다.

- 메뉴바에 무엇을 보여줄지
- 팝오버에 어떤 정보를 배치할지
- 디버그용 화면이 필요한지

### 4.4 `Services/`

OS 또는 외부 시스템과 연결되는 부분이다.

- 전원 감지
- sleep/wake 감지
- 로컬 저장
- 분석 이벤트 로깅

### 4.5 `Supporting/`

상수, 플래그, 설정 등 보조 코드.

---

## 5. Phase 0 기준 최소 구조

처음부터 모든 파일을 만들 필요는 없다.  
`Phase 0`에서는 아래 정도로 시작하면 충분하다.

```text
MacTama/
├─ MacTamaApp.swift
├─ App/
│  ├─ AppDelegate.swift
│  ├─ StatusBarController.swift
│  └─ PopoverController.swift
├─ Domain/
│  ├─ PetState.swift
│  └─ PetEvent.swift
├─ Features/
│  └─ Popover/
│     └─ PopoverView.swift
├─ Services/
│  ├─ Sensors/
│  │  ├─ PowerMonitor.swift
│  │  └─ SleepWakeMonitor.swift
│  └─ Persistence/
│     └─ UserDefaultsPetStateStore.swift
└─ Supporting/
   └─ Constants.swift
```

이 상태에서 먼저 검증할 것:

- 메뉴바에 뜨는가
- 충전 이벤트를 받는가
- sleep/wake 이벤트를 받는가
- 팝오버가 기본적으로 열리는가

---

## 6. 파일별 추천 역할

### `MacTamaApp.swift`

- 앱 엔트리
- 앱 실행 시 전역 객체 연결

### `App/AppDelegate.swift`

- 메뉴바 앱 초기화
- status item과 monitor 시작

### `App/StatusBarController.swift`

- 메뉴바 아이콘/텍스트 업데이트 전담

### `App/PopoverController.swift`

- 팝오버 표시와 닫기 전담

### `Domain/Models/PetState.swift`

- 현재 펫 상태
- 최소 단계에서는 `awake`, `sleeping`, `charging` 정도면 충분

### `Domain/Models/PetEvent.swift`

- `chargingStarted`
- `chargingStopped`
- `sleepEntered`
- `wakeDetected`

### `Services/Sensors/PowerMonitor.swift`

- 전원 연결 상태 감지
- 배터리 상태 확인

### `Services/Sensors/SleepWakeMonitor.swift`

- sleep/wake 알림 수신

### `Services/Persistence/UserDefaultsPetStateStore.swift`

- 최소 상태 저장/복원

### `Features/Popover/PopoverView.swift`

- 현재 상태와 최근 이벤트 표시

---

## 7. 아키텍처 흐름 추천

센서 코드와 UI 코드를 직접 붙이지 말고 아래 흐름으로 간다.

```text
PowerMonitor / SleepWakeMonitor
→ PetEvent 생성
→ PetStateReducer 또는 상태 갱신 로직
→ PetState 변경
→ MenuBar / Popover UI 반영
```

이 구조를 쓰는 이유:

- 센서를 나중에 추가해도 UI가 덜 깨진다
- 테스트 포인트가 생긴다
- `Phase 0.5`와 `v1`로 확장할 때 덜 꼬인다

---

## 8. 처음부터 안 넣는 게 좋은 것

- Core Data
- 과한 DI 프레임워크
- 복잡한 Coordinator 패턴
- 다중 타깃 분리
- 성향 분기 로직
- 픽셀아트 애니메이션 엔진
- CPU 감지
- 공유 기능

이건 `Phase 0`에선 과하다.

---

## 9. Xcode와 ChatGPT를 연결할 수 있는가

짧게 말하면 **가능은 한데, 두 가지 의미로 나눠서 봐야 한다.**

### 9.1 개발 보조로 같이 쓰는 것

가능하다.

현재 OpenAI 공식 Help Center 문서 기준으로, ChatGPT macOS 앱의 `Work with Apps` 기능은 **Xcode를 지원 앱 목록에 포함**한다.  
이 기능을 쓰면 ChatGPT가 현재 Xcode 편집기 내용을 읽고, 코드 수정 제안을 diff 형태로 주는 흐름이 가능하다.

실무적으로는 이런 용도다.

- 현재 열어둔 Swift 파일 설명 요청
- 선택한 코드 리팩터 제안
- 에러 메시지와 코드 컨텍스트를 같이 보내서 디버깅
- 간단한 코드 수정 diff 제안

중요:

- 이건 **Xcode 안에 OpenAI API를 직접 붙이는 것**과는 다르다
- ChatGPT macOS 앱이 Xcode 내용을 읽는 방식이다

### 9.2 MacTama 앱 안에 ChatGPT 기능을 넣는 것

이것도 가능하다.

이 경우에는 Xcode 자체와 연결하는 게 아니라,  
**네가 만드는 macOS 앱이 OpenAI API를 호출**하는 구조다.

예를 들면:

- 펫 상태를 텍스트로 요약
- "오늘 내 맥북 펫 어땠어?" 같은 주간 리포트 생성
- 공유 문구를 더 자연스럽게 생성

이 흐름은 OpenAI 공식 API 문서의 `Responses API`를 기준으로 붙이면 된다.

---

## 10. 어떤 방식이 MacTama에 맞는가

MacTama 기준으로는 두 가지를 분리하는 게 맞다.

### 지금 당장

- Xcode에서 개발할 때는 ChatGPT macOS 앱을 보조 도구로 사용
- 코드 설명, 리팩터, 디버깅 보조에 활용

### 나중에

- 앱 기능으로 AI가 꼭 필요할 때만 OpenAI API를 직접 붙임

지금 단계에서 MacTama에 AI 기능을 바로 넣을 필요는 거의 없다.  
오히려 `Phase 0`, `0.5`, `v1`은 센서 반응과 메뉴바 사용감을 먼저 만드는 게 맞다.

---

## 11. 추천 시작 순서

1. Xcode에서 macOS App 프로젝트 생성
2. 메뉴바 전용 앱 구조 만들기
3. `StatusBarController`, `PopoverController` 생성
4. `PowerMonitor`, `SleepWakeMonitor` 붙이기
5. 이모지 기반 `Phase 0` 완성
6. 상태 저장/이벤트 로그를 붙여 `Phase 0.5` 완성
7. 그 다음 `v1` 수치 시스템으로 확장

---

## 12. 참고 링크

- OpenAI Help Center: [Work with Apps on macOS](https://help.openai.com/en/articles/10119604-work-with-apps-on-macos)
- OpenAI Help Center: [Downloading the ChatGPT macOS app](https://help.openai.com/en/articles/9275200-using-the-chatgpt-macos-app)
- OpenAI Platform Docs: [Developer quickstart](https://platform.openai.com/docs/quickstart/make-your-first-api-request)
- OpenAI Platform Docs: [Responses API](https://platform.openai.com/docs/api-reference/responses/tutorials-and-guides)

참고:

- `Work with Apps`에서 Xcode 지원은 OpenAI Help Center 문서 기준
- "MacTama 앱 내부에 AI 기능 추가"는 OpenAI API 문서를 기준으로 한 추천이며, 이는 Xcode 통합이 아니라 앱의 API 연동이다

---

*MacTama Xcode Setup Notes — 2026-03-31*
