import AppKit
import SwiftUI

@MainActor
final class SettingsPopupPresenter: NSObject, NSWindowDelegate {
    private(set) var panel: NSPanel?
    private var isPresentationSuppressedUntilExplicitHide = false

    func render(
        isPresented: Bool,
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        guard isPresented else {
            panel?.orderOut(nil)
            isPresentationSuppressedUntilExplicitHide = false
            return
        }

        let size = PreferencesView.nativeWindowSize
        let panel = panel ?? makePanel(frame: CGRect(origin: .zero, size: size))
        let hostingView = NSHostingView(
            rootView: PreferencesView(
                settings: settings,
                onSave: onSave,
                onLaunchAtLoginChange: onLaunchAtLoginChange
            )
        )

        panel.setFrame(CGRect(origin: panel.frame.origin, size: size), display: true)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        if !isPresentationSuppressedUntilExplicitHide {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }

        self.panel = panel
    }

    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
        isPresentationSuppressedUntilExplicitHide = true
    }

    private func makePanel(frame: CGRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .fullSizeContentView],
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
