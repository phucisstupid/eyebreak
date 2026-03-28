import SwiftUI

@MainActor
struct ReminderPopupView: View {
    let breakType: BreakType
    let breakDuration: TimeInterval
    let idleDuration: TimeInterval
    let idleThreshold: TimeInterval
    let onStartNow: @MainActor () -> Void
    let onSkip: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EyeBreak")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Break ready")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(
                    "A \(breakType.title.lowercased()) break will start when you're "
                        + "idle for a moment. It lasts \(durationLabel)."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("Start break now", action: onStartNow)
                    .controlSize(.small)

                Button("Skip for now", action: onSkip)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            ProgressLineView(progressValue: progressValue)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 10)
        )
        .padding(4)
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
                    .fill(Color.primary.opacity(0.12))

                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: width)
            }
        }
        .frame(height: 4)
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
