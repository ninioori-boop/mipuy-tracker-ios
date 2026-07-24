import Foundation
import Observation

// App-wide state: the device token (from Keychain) and onboarding progress.
@Observable
final class AppState {
    var token: String?
    var didAskNotifications: Bool

    init() {
        token = KeychainStore.loadToken()
        didAskNotifications = UserDefaults.standard.bool(forKey: "didAskNotifications")
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
}
