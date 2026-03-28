import ServiceManagement

@MainActor
final class LaunchAtLoginController {
    @discardableResult
    func setEnabled(_ enabled: Bool) -> String? {
        let service = SMAppService.mainApp

        do {
            switch (enabled, service.status) {
            case (true, .enabled), (false, .notRegistered):
                return nil
            case (true, _):
                try service.register()
            case (false, _):
                try service.unregister()
            }

            return nil
        } catch {
            return "Launch at login couldn't be updated in this build. The setting is still saved."
        }
    }
}
