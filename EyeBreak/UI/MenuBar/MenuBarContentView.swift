import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    let quit: () -> Void

    private let contentBuilder = MenuContentBuilder()

    var menuContent: MenuContent {
        contentBuilder.build(from: model.snapshot, settings: model.settings)
    }

    var body: some View {
        Text(menuContent.statusLine)
        Text(menuContent.timeUntilNextReminderLine)
        Text(menuContent.waitingForIdleLine)
        Text(menuContent.breakCountLine)
        Text(menuContent.nextBreakTypeLine)
        Divider()
        SettingsLink()
        Button("Pause reminders") {
            model.pauseReminders()
        }
        .disabled(!menuContent.canPause)
        Button("Resume reminders") {
            model.resumeReminders()
        }
        .disabled(!menuContent.canResume)
        Button("Skip current reminder") {
            model.skipCurrentReminder()
        }
        .disabled(!menuContent.canSkipReminder)
        Divider()
        Button("Quit EyeBreak", action: quit)
    }
}
