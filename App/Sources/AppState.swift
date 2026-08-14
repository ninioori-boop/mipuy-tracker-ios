import Foundation
import Observation

// App-wide state: the device token (from Keychain) and onboarding progress.
@Observable
final class AppState {
    var token: String?
    var didAskNotifications: Bool
    // Whether the user has been walked through creating the Wallet automation.
    // Without the automation the app records nothing at all, so this is not a
    // nicety — it is the difference between a working install and a dead one.
    var didSetupAutomation: Bool

    init() {
        token = KeychainStore.loadToken()
        didAskNotifications = UserDefaults.standard.bool(forKey: "didAskNotifications")
        didSetupAutomation = UserDefaults.standard.bool(forKey: "didSetupAutomation")
    }

    func setToken(_ newToken: String) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainStore.saveToken(trimmed)
        token = trimmed
    }

    func disconnect() {
        KeychainStore.deleteToken()
        token = nil
    }

    func markAskedNotifications() {
        didAskNotifications = true
        UserDefaults.standard.set(true, forKey: "didAskNotifications")
    }

    func markAutomationSetup() {
        didSetupAutomation = true
        UserDefaults.standard.set(true, forKey: "didSetupAutomation")
    }
}
