import SwiftUI

@MainActor
struct ReminderWindowView: View {
    let breakType: BreakType
    let breakDuration: TimeInterval
    let idleDuration: TimeInterval
    let idleThreshold: TimeInterval
    let onSkip: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void

    var body: some View {
        ReminderPopupView(
            breakType: breakType,
            breakDuration: breakDuration,
            idleDuration: idleDuration,
            idleThreshold: idleThreshold,
            onSkip: onSkip,
            onPostpone: onPostpone
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
