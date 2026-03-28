import AppKit
import SwiftUI

@MainActor
final class BreakOverlayPresenter {
    private var panel: BreakOverlayPanel?
    private var hostingView: NSHostingView<BreakOverlayView>?

    var panelForTesting: NSPanel? {
        panel
    }

    var hostingViewForTesting: NSHostingView<BreakOverlayView>? {
        hostingView
    }

    func render(
        isPresented: Bool,
        remainingSeconds: Int,
        totalSeconds: Int,
        onSkip: @escaping @MainActor () -> Void
    ) {
        guard isPresented else {
            hide()
            return
        }

        show(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            onSkip: onSkip
        )
    }

    func show(remainingSeconds: Int, totalSeconds: Int, onSkip: @escaping @MainActor () -> Void) {
        guard
            let screenFrame = PresentationScreenSelector.preferredFrame(
                primaryFrame: NSScreen.screens.first?.frame,
                activeFrame: NSScreen.main?.frame,
                fallbackFrames: Array(NSScreen.screens.dropFirst().map(\.frame))
            )
        else {
            return
        }

        let panel = panel ?? makePanel(frame: screenFrame)
        let hostingView =
            hostingView
            ?? makeHostingView(
                remainingSeconds: remainingSeconds,
                totalSeconds: totalSeconds,
                onSkip: onSkip
            )
        panel.setFrame(screenFrame, display: true)
        hostingView.frame = CGRect(origin: .zero, size: screenFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.rootView = BreakOverlayView(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            onSkip: onSkip
        )
        if panel.contentView !== hostingView {
            panel.contentView = hostingView
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil as Any?)
        self.panel = panel
        self.hostingView = hostingView
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makeHostingView(
        remainingSeconds: Int,
        totalSeconds: Int,
        onSkip: @escaping @MainActor () -> Void
    ) -> NSHostingView<BreakOverlayView> {
        NSHostingView(
            rootView: BreakOverlayView(
                remainingSeconds: remainingSeconds,
                totalSeconds: totalSeconds,
                onSkip: onSkip
            )
        )
    }

    private func makePanel(frame: CGRect) -> BreakOverlayPanel {
        let panel = BreakOverlayPanel(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = false
        return panel
    }
}

private final class BreakOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

enum PresentationScreenSelector {
    static func preferredFrame(
        primaryFrame: CGRect?,
        activeFrame: CGRect?,
        fallbackFrames: [CGRect]
    ) -> CGRect? {
        primaryFrame ?? activeFrame ?? fallbackFrames.first
    }
}
