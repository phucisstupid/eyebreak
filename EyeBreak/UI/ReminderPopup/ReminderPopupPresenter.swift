import AppKit
import SwiftUI

@MainActor
final class ReminderPopupPresenter {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<ReminderWindowView>?

    var panelForTesting: NSPanel? { panel }
    var hostingViewForTesting: NSHostingView<ReminderWindowView>? { hostingView }

    func render(
        isPresented: Bool,
        breakType: BreakType,
        breakDuration: TimeInterval,
        idleDuration: TimeInterval,
        idleThreshold: TimeInterval,
        onStartNow: @escaping @MainActor () -> Void,
        onSkip: @escaping @MainActor () -> Void
    ) {
        guard isPresented else {
            panel?.orderOut(nil)
            return
        }

        guard let frame = NSScreen.main?.visibleFrame else { return }
        let size = CGSize(width: 320, height: 128)
        let origin = CGPoint(x: frame.midX - size.width / 2, y: frame.maxY - size.height - 12)
        let panel = panel ?? makePanel(frame: CGRect(origin: origin, size: size))
        let hostingView = hostingView ?? NSHostingView(rootView: ReminderWindowView(
            breakType: breakType,
            breakDuration: breakDuration,
            idleDuration: idleDuration,
            idleThreshold: idleThreshold,
            onStartNow: onStartNow,
            onSkip: onSkip
        ))

        panel.setFrame(CGRect(origin: origin, size: size), display: true)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.rootView = ReminderWindowView(
            breakType: breakType,
            breakDuration: breakDuration,
            idleDuration: idleDuration,
            idleThreshold: idleThreshold,
            onStartNow: onStartNow,
            onSkip: onSkip
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

@MainActor
struct ReminderWindowRouter {
    enum Action: Equatable {
        case open
        case dismiss
        case none
    }

    private(set) var desiredPresentation = false
    private(set) var isWindowVisible = false

    mutating func updateDesiredPresentation(_ desiredPresentation: Bool) -> Action {
        self.desiredPresentation = desiredPresentation

        if desiredPresentation {
            return isWindowVisible ? .none : .open
        }

        return isWindowVisible ? .dismiss : .none
    }

    mutating func updateWindowVisibility(_ isWindowVisible: Bool) -> Action {
        self.isWindowVisible = isWindowVisible

        if !isWindowVisible, desiredPresentation {
            return .open
        }

        return .none
    }
}
