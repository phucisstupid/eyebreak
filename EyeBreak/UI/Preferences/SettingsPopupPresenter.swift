import AppKit
import SwiftUI

@MainActor
final class SettingsPopupPresenter: NSObject, NSWindowDelegate {
    private var hostingView: NSHostingView<PreferencesView>?
    private(set) var panel: NSPanel?

    func render(
        isPresented: Bool,
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        guard isPresented else {
            panel?.orderOut(nil)
            return
        }

        let size = PreferencesView.nativeWindowSize
        let frame = CGRect(origin: .zero, size: size)
        let panel = panel ?? makePanel(frame: frame)
        let hostingView =
            hostingView
            ?? NSHostingView(
                rootView: PreferencesView(
                    settings: settings,
                    onSave: onSave,
                    onLaunchAtLoginChange: onLaunchAtLoginChange
                )
            )

        panel.setFrame(frame, display: true)
        hostingView.frame = frame
        hostingView.autoresizingMask = [.width, .height]
        hostingView.rootView = PreferencesView(
            settings: settings,
            onSave: onSave,
            onLaunchAtLoginChange: onLaunchAtLoginChange
        )
        if panel.contentView !== hostingView {
            panel.contentView = hostingView
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
        self.hostingView = hostingView
    }

    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
    }

    private func makePanel(frame: CGRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.delegate = self
        return panel
    }
}
