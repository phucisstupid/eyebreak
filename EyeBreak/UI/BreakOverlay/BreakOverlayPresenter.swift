import AppKit
import SwiftUI

@MainActor
final class BreakOverlayPresenter {
    private var panel: BreakOverlayPanel?
    private var hostingView: NSHostingView<BreakOverlayView>?
    private let now: () -> Date
    private var skipAction: (@MainActor () -> Void)?
    private var lastEscapePressAt: Date?

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

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
        onSkip: @escaping @MainActor () -> Void,
        onPostpone: @escaping @MainActor () -> Void
    ) {
        guard isPresented else {
            hide()
            return
        }

        show(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            onSkip: onSkip,
            onPostpone: onPostpone
        )
    }

    func show(
        remainingSeconds: Int,
        totalSeconds: Int,
        onSkip: @escaping @MainActor () -> Void,
        onPostpone: @escaping @MainActor () -> Void
    ) {
        guard
            let screenFrame = PresentationScreenSelector.preferredFrame(
                primaryFrame: NSScreen.screens.first?.frame,
                activeFrame: NSScreen.main?.frame,
                fallbackFrame: NSScreen.screens.dropFirst().first?.frame
            )
        else {
            return
        }

        let panel = panel ?? makePanel(frame: screenFrame)
        skipAction = onSkip
        let hostingView =
            hostingView
            ?? makeHostingView(
                remainingSeconds: remainingSeconds,
                totalSeconds: totalSeconds,
                onSkip: onSkip,
                onPostpone: onPostpone
            )
        panel.setFrame(screenFrame, display: true)
        hostingView.frame = CGRect(origin: .zero, size: screenFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.rootView = BreakOverlayView(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            onSkip: onSkip,
            onPostpone: onPostpone
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
        lastEscapePressAt = nil
    }

    private func makeHostingView(
        remainingSeconds: Int,
        totalSeconds: Int,
        onSkip: @escaping @MainActor () -> Void,
        onPostpone: @escaping @MainActor () -> Void
    ) -> NSHostingView<BreakOverlayView> {
        NSHostingView(
            rootView: BreakOverlayView(
                remainingSeconds: remainingSeconds,
                totalSeconds: totalSeconds,
                onSkip: onSkip,
                onPostpone: onPostpone
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
        panel.onEscape = { [weak self] in
            self?.handleEscapeKeyPress()
        }
        return panel
    }

    func handleEscapeKeyPress() {
        let pressedAt = now()

        if let lastEscapePressAt {
            if pressedAt.timeIntervalSince(lastEscapePressAt) <= Self.escapeConfirmationWindow {
                self.lastEscapePressAt = nil
                skipAction?()
                return
            }
        }

        lastEscapePressAt = pressedAt
    }

    private static let escapeConfirmationWindow: TimeInterval = 1.2
}

private final class BreakOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 53 else {
            super.keyDown(with: event)
            return
        }

        onEscape?()
    }
}

enum PresentationScreenSelector {
    static func preferredFrame(
        primaryFrame: CGRect?,
        activeFrame: CGRect?,
        fallbackFrame: CGRect?
    ) -> CGRect? {
        activeFrame ?? primaryFrame ?? fallbackFrame
    }
}
