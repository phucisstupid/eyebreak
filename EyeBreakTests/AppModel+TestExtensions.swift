import Foundation

@testable import EyeBreak

extension AppModel {
    static func makeForTests(
        coordinator: any AppCoordinating = AppCoordinator(),
        launchAtLoginController: any LaunchAtLoginControlling = LaunchAtLoginController(),
        snapshot: AppSnapshot? = nil,
        settings: AppSettings? = nil
    ) -> AppModel {
        AppModel(
            coordinator: coordinator,
            launchAtLoginController: launchAtLoginController,
            snapshot: snapshot,
            settings: settings
        )
    }
}
