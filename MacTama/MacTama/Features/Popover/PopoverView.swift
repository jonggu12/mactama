import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        let state = appEnvironment.petState

        return ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(state.menuBarTitle)
                        .font(.system(size: 34))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.statusLabel)
                            .font(.title3.weight(.semibold))
                    }
                }

                Text(state.stateDescription)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Divider()

                Text("최근 이벤트")
                    .font(.subheadline.weight(.semibold))

                if state.recentEvents.isEmpty {
                    Text("최근 이벤트가 쌓이면 여기에 보여요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(state.recentEvents) { entry in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.event.title)
                                Text(entry.event.detail)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.occurredAt, style: .time)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }

                Divider()

                HStack {
                    Text("현재 성향")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(state.traitStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

#if DEBUG
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("BehaviorHistory")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(appEnvironment.debugBehaviorSummary, id: \.self) { line in
                            Text(line)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    Text("디버그 테스트")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("저배터리") {
                            appEnvironment.debugSimulateLowBattery()
                        }
                        Button("배터리 회복") {
                            appEnvironment.debugRecoverBattery()
                        }
                    }
                    .buttonStyle(.bordered)

                    HStack {
                        Button("Critical") {
                            appEnvironment.debugForceCriticalFatigue()
                        }
                        Button("리셋") {
                            appEnvironment.debugResetRhythm()
                        }
                    }
                    .buttonStyle(.bordered)
                }
#endif

                Spacer(minLength: 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.visible)
        .frame(width: Constants.popoverSize.width, height: Constants.popoverSize.height)
    }
}
