import AppKit
import SwiftUI

@MainActor
final class SettingsPopupPresenter: NSObject, NSWindowDelegate {
    private static let topInset: CGFloat = 12
    private static let trailingInset: CGFloat = 16

    private(set) var panel: NSPanel?
    private var isSuppressedUntilExplicitPresent = false

    func present(
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        isSuppressedUntilExplicitPresent = false
        render(
            isPresented: true,
            settings: settings,
            onSave: onSave,
            onLaunchAtLoginChange: onLaunchAtLoginChange
        )
    }

    func render(
        isPresented: Bool,
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        guard isPresented else {
            panel?.orderOut(nil)
            isSuppressedUntilExplicitPresent = false
            return
        }

        let size = PreferencesView.nativeWindowSize
        let panel = panel ?? makePanel(frame: defaultFrame(for: size))
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

        if !isSuppressedUntilExplicitPresent {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }

        self.panel = panel
    }

    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
        isSuppressedUntilExplicitPresent = true
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

    private func defaultFrame(for size: CGSize) -> CGRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(origin: .zero, size: size)
        let origin = Self.defaultOrigin(for: size, in: visibleFrame)
        return CGRect(origin: origin, size: size)
    }

    static func defaultOrigin(for size: CGSize, in visibleFrame: CGRect) -> CGPoint {
        CGPoint(
            x: visibleFrame.maxX - size.width - trailingInset,
            y: visibleFrame.maxY - size.height - topInset
        )
    }
}
