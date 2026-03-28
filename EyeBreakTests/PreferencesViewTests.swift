import SwiftUI
import XCTest

@testable import EyeBreak

@MainActor
final class PreferencesViewTests: XCTestCase {
    func test_prefersNativeFormSpacingAndWindowFootprint() {
        _ = PreferencesView(
            settings: .default,
            onSave: { _ in },
            onLaunchAtLoginChange: { _ in nil }
        )

        let size = PreferencesView.nativeWindowSize

        XCTAssertEqual(size.width, 480, accuracy: 0.5)
        XCTAssertEqual(size.height, 330, accuracy: 0.5)
    }

    func test_launchAtLoginToggleRoutesThroughPreferencesViewAndAppModel() {
        let coordinator = SpyAppCoordinator(settings: .default)
        let launchAtLoginController = SpyLaunchAtLoginController()
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
        XCTAssertTrue(coordinator.settings.launchAtLogin)
        XCTAssertEqual(launchAtLoginController.enabledValues, [true])
    }

    func test_integerFieldParserNormalizesInputWithinConfiguredRange() {
        let parser = PreferencesIntegerFieldParser(range: 1...120)

        XCTAssertEqual(parser.normalizedText(from: " 15 ", fallback: 20), "15")
        XCTAssertEqual(parser.normalizedText(from: "0", fallback: 20), "1")
        XCTAssertEqual(parser.normalizedText(from: "999", fallback: 20), "120")
        XCTAssertEqual(parser.normalizedText(from: "abc", fallback: 20), "20")
    }
}

@MainActor
private final class SpyLaunchAtLoginController: LaunchAtLoginControlling {
    private(set) var enabledValues: [Bool] = []

    func setEnabled(_ enabled: Bool) -> String? {
        enabledValues.append(enabled)
        return nil
    }
}

private final class SpyAppCoordinator: AppCoordinating {
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

    func skipCurrentBreak() {}

    func startBreakNow() {}

    func updateSettings(_ settings: AppSettings) {
        updateSettingsValues.append(settings)
        self.settings = settings
    }
}
