import AppKit
import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var model: AppModel
    let quit: () -> Void
    let openSettings: () -> Void

    init(
        model: AppModel,
        quit: @escaping () -> Void,
        openSettings: @escaping () -> Void = {}
    ) {
        self.model = model
        self.quit = quit
        self.openSettings = openSettings
    }

    var body: some View {
        MenuBarContentView(
            model: model,
            quit: quit,
            openSettings: openSettings
        )
    }
}

struct MenuBarContentView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var model: AppModel
    let quit: () -> Void
    let openSettings: () -> Void

    private let contentBuilder = MenuContentBuilder()

    init(
        model: AppModel,
        quit: @escaping () -> Void,
        openSettings: @escaping () -> Void = {}
    ) {
        self.model = model
        self.quit = quit
        self.openSettings = openSettings
    }

    var menuContent: MenuContent {
        contentBuilder.build(from: model.snapshot, settings: model.settings)
    }

    var pauseResumeIconName: String {
        menuContent.canResume ? "play.fill" : "pause.fill"
    }

    var pauseResumeAccessibilityLabel: String {
        menuContent.canResume ? "Resume reminders" : "Pause reminders"
    }

    var canTogglePauseResume: Bool {
        menuContent.canPause || menuContent.canResume
    }

    func togglePauseResume(dismissMenu: () -> Void = {}) {
        if menuContent.canResume {
            model.resumeReminders()
        } else if menuContent.canPause {
            model.pauseReminders()
        }

        dismissMenu()
    }

    func startBreakNow(dismissMenu: () -> Void = {}) {
        dismissMenu()
        DispatchQueue.main.async {
            model.startBreakNow()
        }
    }

    func showSettings(dismissMenu: () -> Void = {}) {
        dismissMenu()
        DispatchQueue.main.async {
            openSettings()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button("Start this break now") {
                    startBreakNow(dismissMenu: dismiss.callAsFunction)
                }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!menuContent.canStartBreakNow)

                Button {
                    togglePauseResume(dismissMenu: dismiss.callAsFunction)
                } label: {
                    Image(systemName: pauseResumeIconName)
                        .frame(width: 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(pauseResumeAccessibilityLabel)
                .accessibilityLabel(pauseResumeAccessibilityLabel)
                .disabled(!canTogglePauseResume)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(menuContent.statusLine)
                Text(menuContent.timeUntilNextReminderLine)
                Text(menuContent.waitingForIdleLine)
                Text(menuContent.breakCountLine)
                Text(menuContent.nextBreakTypeLine)
            }
            .font(.subheadline)
            .foregroundStyle(.primary)

            Divider()

            Button("Settings") {
                showSettings(dismissMenu: dismiss.callAsFunction)
            }

            Button("Skip current reminder") {
                model.skipCurrentReminder()
                dismiss()
            }
            .disabled(!menuContent.canSkipReminder)

            Divider()

            Button("Quit EyeBreak", action: quit)
        }
        .padding(12)
        .frame(minWidth: 280, alignment: .topLeading)
    }
}
