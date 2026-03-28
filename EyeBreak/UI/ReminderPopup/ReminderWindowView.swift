import SwiftUI

@MainActor
struct ReminderWindowView: View {
    let breakType: BreakType
    let breakDuration: TimeInterval
    let idleDuration: TimeInterval
    let idleThreshold: TimeInterval
    let onStartNow: @MainActor () -> Void
    let onSkip: @MainActor () -> Void

    var body: some View {
        ReminderPopupView(
            breakType: breakType,
            breakDuration: breakDuration,
            idleDuration: idleDuration,
            idleThreshold: idleThreshold,
            onStartNow: onStartNow,
            onSkip: onSkip
        )
        .frame(minWidth: 320, idealWidth: 320)
    }

    var progressValue: Double {
        ReminderPopupView.progressValue(
            idleDuration: idleDuration,
            idleThreshold: idleThreshold
        )
    }
}
