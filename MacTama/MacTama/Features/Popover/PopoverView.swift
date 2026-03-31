import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        let state = appEnvironment.petState

        return VStack(alignment: .leading, spacing: 14) {
            Text("MacTama")
                .font(.headline)

            HStack(spacing: 12) {
                Text(state.menuBarTitle)
                    .font(.system(size: 34))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.statusLabel)
                        .font(.title3.weight(.semibold))
                    Text(state.powerDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Group {
                if let latestEvent = state.mostRecentEvent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(latestEvent.event.title)
                            .font(.caption.weight(.semibold))
                        Text(latestEvent.event.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("아직 기록된 이벤트가 없어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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

            Spacer()
        }
        .padding(16)
        .frame(width: Constants.popoverSize.width, height: Constants.popoverSize.height)
    }
}
