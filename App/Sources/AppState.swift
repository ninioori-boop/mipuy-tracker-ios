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

    /// Bumped by every successful sign-in, including one that hands back the
    /// SAME device token.
    ///
    /// 🔴 The web session lives inside the WKWebView, and the only thing that
    /// creates a new one is `/connect/expenses#token=…` being loaded again —
    /// that page is what calls `signInWithCustomToken`. WebShellView used to key
    /// the web view on the token alone, and `signDeviceToken` is a deterministic
    /// HMAC over the uid that returns a byte-identical string every time (on
    /// purpose, so tokens already handed out keep working). Same value, same
    /// SwiftUI identity, no reload: a person signed in through the native form
    /// and their web session came out exactly as old as it went in.
    ///
    /// That is why deleting an account was impossible from this app. The web
    /// requires a sign-in from the last few minutes before it will delete; the
    /// sheet opened, the sign-in succeeded, nothing reached the page, and the
    /// same panel came back. Android never had this — `renderHome()` builds a
    /// new WebView and loads the token URL unconditionally.
    ///
    /// A counter, not the token, because the token is precisely the thing that
    /// does not change. It lives here rather than in a view because this is the
    /// one junction all three sign-in routes pass through: the re-auth sheet,
    /// Settings, and the Safari connect flow.
    private(set) var sessionEpoch = 0

    func setToken(_ newToken: String) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainStore.saveToken(trimmed)
        token = trimmed
        // Deliberately NOT bumped in init(): a cold start already loads the
        // token URL from scratch, and counting a launch here would rebuild a
        // web view that had only just been created.
        sessionEpoch += 1
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
