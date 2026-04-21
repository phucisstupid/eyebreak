import SwiftUI

@MainActor
struct ReminderWindowView: View {
    let state: ReminderPopupPresenter.PresentationState
    let onSkip: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void

    var body: some View {
        ReminderPopupView(
            state: state,
            onSkip: onSkip,
            onPostpone: onPostpone
        )
        .frame(minWidth: 320, idealWidth: 320)
    }

    var progressValue: Double {
        ReminderPopupView.progressValue(
            idleDuration: state.idleDuration,
            idleThreshold: state.idleThreshold
        )
    }
}
