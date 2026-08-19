import Foundation

// Single source of truth for URLs and scheme constants.
// Mirrors the Android shell's NotificationListener companion constants.
enum Config {
    static let baseURL = URL(string: "https://app.orimipuy.com")!

    /// The in-WebView launcher page: exchanges the device token (in the URL
    /// fragment — never sent to the server) for a Firebase session and lands
    /// on the logged-in expenses tab.
    static func expensesURL(token: String) -> URL {
        URL(string: "\(baseURL)/connect/expenses#token=\(token.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? token)")!
    }

    /// Login page opened in system Safari. ?native=1 tells it to hand the
    /// device token back via the mipuytracker:// deep link (like Android)
    /// instead of the iOS copy-token flow.
    static let connectURL = URL(string: "https://app.orimipuy.com/connect?native=1")!

    static let transactionEndpoint = URL(string: "https://app.orimipuy.com/api/transaction")!

    /// Mints the caller's personal device token from a Firebase ID token. It
    /// predates this app — /connect has always called it — which is why native
    /// sign-in needed no server work at all.
    static let deviceTokenEndpoint = URL(string: "https://app.orimipuy.com/api/device-token")!

    /// Firebase Web API key, injected at build time (GitHub secret → fastlane
    /// xcargs → Info.plist). Empty in a local or misconfigured build, which
    /// HIDES the password form rather than shipping one that always fails.
    ///
    /// It is not a secret in the password sense — Firebase keys are public by
    /// design and one already ships inside the website's JavaScript — but it
    /// stays out of the repo because the project rule is that API keys never
    /// live in source. Restrict it to this bundle ID in Google Cloud; see
    /// NativeAuth.googleRequest for the header that makes that restriction work.
    static let firebaseAPIKey = (Bundle.main.infoDictionary?["FirebaseAPIKey"] as? String ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    /// Google's own password endpoint, the one the website's Firebase SDK calls
    /// internally. Talking to it directly is what keeps the password off our
    /// server entirely.
    static var passwordSignInEndpoint: URL? {
        guard !firebaseAPIKey.isEmpty else { return nil }
        return URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(firebaseAPIKey)")
    }

    /// Password-reset mail. Same key, same reasoning.
    static var sendOobCodeEndpoint: URL? {
        guard !firebaseAPIKey.isEmpty else { return nil }
        return URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=\(firebaseAPIKey)")
    }

    /// Custom URL scheme shared with the Android app and the /connect page.
    static let scheme = "mipuytracker"

    /// The ready-made shortcut a client imports in one tap: a Text action that
    /// pulls «כמות» and «בית עסק» off the Wallet transaction and feeds our
    /// capture action. Built and verified on a real charge, 2026-08-15.
    ///
    /// This link is the difference between a product and a science project.
    /// Those two properties can only be picked while editing inside an
    /// automation — Apple does not offer «עסקה» as a declarable input type — so
    /// no client could reproduce it from written instructions in any reasonable
    /// number of taps. Sharing the finished shortcut sidesteps that completely:
    /// the property references survive in the file and resolve at run time even
    /// though the editor renders them as a bare "קלט של קיצור".
    ///
    /// Verified to carry no device token, and it structurally cannot: the token
    /// lives in the app's Keychain. That is exactly what made the OLD web
    /// shortcut unshareable — it held a live token in plain sight.
    /// ⚠️ Re-verify emptiness before ever swapping this link for another.
    static let captureShortcutURL = URL(string: "https://www.icloud.com/shortcuts/c7c8bb8cfa0c4fe69cead5cdd61ddc8f")!

    /// 25-second silent screen recording of the whole setup, filmed on a real
    /// device. Reviewed frame by frame before publishing: it shows only the
    /// Shortcuts app, never the expenses screens, so no one's finances are in it.
    /// Also handed to Apple's reviewer, who otherwise has to imagine the flow.
    static let setupVideoURL = URL(string: "https://app.orimipuy.com/ios-setup.mp4")!
}
