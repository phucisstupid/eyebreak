import SwiftUI

@MainActor
struct BreakOverlayView: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let onSkip: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color(nsColor: .underPageBackgroundColor)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .padding(48)

            VStack(spacing: 24) {
                Text("Time to reset your eyes")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(timeLabel)
                    .font(.system(size: 112, weight: .heavy, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .accessibilityLabel("Remaining break time \(timeLabel)")

                ProgressLineView(progressValue: progressValue)
                    .frame(maxWidth: 440)

                Text(
                    "Look away from the screen. Let the countdown finish, "
                        + "or postpone once if you need a few more minutes."
                )
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 720)

                Button("Skip and remind me in 5 minutes", action: onSkip)
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Postpones the reminder for five minutes")
            }
            .padding(60)
        }
    }

    var progressValue: Double {
        guard totalSeconds > 0 else {
            return 0
        }

        return min(max(Double(remainingSeconds) / Double(totalSeconds), 0), 1)
    }

    private var timeLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
