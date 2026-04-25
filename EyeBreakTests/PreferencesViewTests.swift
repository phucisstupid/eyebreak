import AppKit
import SwiftUI
import XCTest

@testable import EyeBreak

@MainActor
final class PreferencesViewTests: XCTestCase {
    func test_prefersNativeFormSpacingAndWindowFootprint() throws {
        XCTAssertEqual(
            PreferencesView.nativeWindowSize,
            CGSize(width: 360, height: 250)
        )
    }

    func test_rendersCompactNumericFieldWidth() throws {
        let hostingView = makeHostingView()

        hostingView.frame = CGRect(origin: .zero, size: PreferencesView.nativeWindowSize)
        hostingView.layoutSubtreeIfNeeded()

        let numericField = try XCTUnwrap(
            allSubviews(of: NSTextField.self, in: hostingView)
                .first { !$0.stringValue.isEmpty }
        )

        XCTAssertGreaterThan(numericField.frame.width, 0)
        XCTAssertLessThanOrEqual(numericField.frame.width, PreferencesView.numericFieldWidth)
    }

    func test_launchAtLoginToggleUsesTheSavePathAndLaunchAtLoginChangeCallback() {
        var savedSettings: [AppSettings] = []
        var launchAtLoginValues: [Bool] = []
        let view = PreferencesView(
            settings: .default,
            onSave: { savedSettings.append($0) },
            onLaunchAtLoginChange: { enabled in
                launchAtLoginValues.append(enabled)
                return nil
            }
        )

        view.launchAtLoginBinding.wrappedValue = true

        XCTAssertEqual(savedSettings.count, 1)
        XCTAssertEqual(savedSettings.first?.launchAtLogin, true)
        XCTAssertEqual(launchAtLoginValues, [true])
    }

    func test_launchAtLoginToggleUpdatesAppModelOnlyOnce() {
        let coordinator = PreferencesSpyAppCoordinator(settings: .default)
        let launchAtLoginController = PreferencesSpyLaunchAtLoginController()
        let model = AppModel.makeForTests(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController
        )
        let view = PreferencesView(
            settings: model.settings,
            onSave: model.updateSettings,
            onLaunchAtLoginChange: model.setLaunchAtLogin
        )

        view.launchAtLoginBinding.wrappedValue = true

        XCTAssertEqual(coordinator.updateSettingsValues.count, 1)
        XCTAssertEqual(coordinator.updateSettingsValues.first?.launchAtLogin, true)
        XCTAssertTrue(model.settings.launchAtLogin)
        XCTAssertEqual(launchAtLoginController.enabledValues, [true])
    }

    func test_integerFieldParserNormalizesInputWithinConfiguredRange() {
        let parser = PreferencesIntegerFieldParser(range: 1...120)

        XCTAssertEqual(parser.normalizedValue(from: " 15 ", fallback: 20), 15)
        XCTAssertEqual(parser.normalizedValue(from: "0", fallback: 20), 1)
        XCTAssertEqual(parser.normalizedValue(from: "999", fallback: 20), 120)
        XCTAssertEqual(parser.normalizedValue(from: "abc", fallback: 20), 20)
    }

    private func makeHostingView() -> NSHostingView<PreferencesView> {
        NSHostingView(
            rootView: PreferencesView(
                settings: .default,
                onSave: { _ in },
                onLaunchAtLoginChange: { _ in nil }
            )
        )
    }

    private func allSubviews<T: NSView>(of type: T.Type, in view: NSView) -> [T] {
        var results: [T] = []

        for subview in view.subviews {
            if let typedSubview = subview as? T {
                results.append(typedSubview)
            }

            results.append(contentsOf: allSubviews(of: type, in: subview))
        }

        return results
    }
}

private final class PreferencesSpyAppCoordinator: AppCoordinating {
    var settings: AppSettings
    var snapshot: AppSnapshot
    var updateSettingsValues: [AppSettings] = []

    init(settings: AppSettings) {
        self.settings = settings
        self.snapshot = .initial(settings: settings)
    }

    func observeStateChanges(
        _ observer: @escaping (AppSnapshot, AppSettings) -> Void
    ) -> AppStateObservationToken {
        UUID()
    }

    func removeStateChangeObserver(_ token: AppStateObservationToken) {}

    func start() {}

    func stop() {}

    func pauseReminders() {}

    func resumeReminders() {}

    func skipCurrentReminder() {}

    func postponeCurrentReminder() {}

    func skipCurrentBreak() {}

    func postponeCurrentBreak() {}

    func startBreakNow() {}

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        updateSettingsValues.append(settings)
    }
}

private final class PreferencesSpyLaunchAtLoginController: LaunchAtLoginControlling {
    var enabledValues: [Bool] = []

    @discardableResult
    func setEnabled(_ enabled: Bool) -> String? {
        enabledValues.append(enabled)
        return nil
    }
}
