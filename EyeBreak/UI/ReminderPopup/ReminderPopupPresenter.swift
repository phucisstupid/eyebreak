import AppKit
import SwiftUI

@MainActor
final class ReminderPopupPresenter {
    struct PresentationState: Equatable {
        let breakType: BreakType
        let breakDuration: TimeInterval
        let idleDuration: TimeInterval
        let idleThreshold: TimeInterval
    }

    private var panel: NSPanel?
    private var hostingView: NSHostingView<ReminderWindowView>?

    #if DEBUG
        var panelForTesting: NSPanel? { panel }
        var hostingViewForTesting: NSHostingView<ReminderWindowView>? { hostingView }
    #endif

    func render(
        isPresented: Bool,
        state: PresentationState,
        onSkip: @escaping @MainActor () -> Void,
        onPostpone: @escaping @MainActor () -> Void
    ) {
        guard isPresented else {
            panel?.orderOut(nil)
            return
        }

        guard
            let frame = PresentationScreenSelector.preferredFrame(
                primaryFrame: NSScreen.screens.first?.visibleFrame,
                activeFrame: NSScreen.main?.visibleFrame,
                fallbackFrame: NSScreen.screens.dropFirst().first?.visibleFrame
            )
        else {
            return
        }
        let size = CGSize(width: 320, height: 128)
        let origin = CGPoint(x: frame.midX - size.width / 2, y: frame.maxY - size.height - 12)
        let panel = panel ?? makePanel(frame: CGRect(origin: origin, size: size))
        let hostingView =
            hostingView
            ?? NSHostingView(
                rootView: ReminderWindowView(




                    state: state,
                    onSkip: onSkip,
                    onPostpone: onPostpone
                ))

        panel.setFrame(CGRect(origin: origin, size: size), display: true)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.rootView = ReminderWindowView(




            state: state,
            onSkip: onSkip,
            onPostpone: onPostpone
        )
        if panel.contentView !== hostingView {
            panel.contentView = hostingView
        }
        panel.orderFrontRegardless()
        self.panel = panel
        self.hostingView = hostingView
    }

    private func makePanel(frame: CGRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        return panel
    }
}
