import SwiftUI

@MainActor
struct ReminderPopupView: View {
    let breakType: BreakType
    let breakDuration: TimeInterval
    let idleDuration: TimeInterval
    let idleThreshold: TimeInterval
    let onSkip: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Break ready")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Text(
                "A \(breakType.title.lowercased()) break will start when you're "
                    + "idle for a moment. It lasts \(durationLabel)."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("Skip", action: onSkip)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Postpone 5 minutes", action: onPostpone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            ProgressLineView(progressValue: progressValue)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                )
        )
        .padding(2)
    }

    var progressValue: Double {
        Self.progressValue(
            idleDuration: idleDuration,
            idleThreshold: idleThreshold
        )
    }

    static func progressValue(idleDuration: TimeInterval, idleThreshold: TimeInterval) -> Double {
        guard idleThreshold > 0 else {
            return 0
        }

        let normalizedIdle = min(max(idleDuration / idleThreshold, 0), 1)
        return 1 - normalizedIdle
    }

    private var durationLabel: String {
        if breakDuration >= 60, breakDuration.truncatingRemainder(dividingBy: 60) == 0 {
            return "\(Int(breakDuration / 60)) minute\(breakDuration == 60 ? "" : "s")"
        }

        return "\(Int(breakDuration)) seconds"
    }
}

struct ProgressLineView: View {
    let progressValue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * max(0, min(progressValue, 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(nsColor: .separatorColor).opacity(0.28))

                Capsule()
                    .fill(Color.accentColor.opacity(0.78))
                    .frame(width: width)
            }
        }
        .frame(height: 3)
        .accessibilityHidden(true)
    }
}

extension BreakType {
    fileprivate var title: String {
        switch self {
        case .short:
            return "Short"
        case .long:
            return "Long"
        }
    }
}
