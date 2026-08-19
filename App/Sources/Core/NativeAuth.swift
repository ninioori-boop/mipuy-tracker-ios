import Foundation

/// Email + password sign-in that never opens a browser of any kind.
///
/// 🔴 Why this exists. Apple rejected 1.0 (21) twice under guideline 4 because
/// sign-in left for the default browser. Build 22 moved it into an in-app
/// ASWebAuthenticationSession sheet, which answers the letter — Apple names
/// Safari View Controller as an acceptable resolution — but sign-in was still a
/// web page, which left the whole category one reviewer's opinion away from a
/// third rejection. This path removes the browser from the argument.
///
/// Two plain HTTPS calls, no SDK, no web view:
///
/// 1. POST the credentials to Google's Identity Toolkit, the same endpoint the
///    website's Firebase SDK calls internally, and get a Firebase ID token.
///    🔒 The password travels phone → Google. It never reaches our server.
/// 2. GET /api/device-token with that ID token. That route predates the app and
///    is exactly what /connect has always called, so **nothing on the server
///    changes for this feature** — which is what makes shipping it safe.
enum NativeAuth {
    enum Failure: LocalizedError {
        case notConfigured
        case badCredentials
        case tooManyAttempts
        case accountDisabled
        case offline
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                // A build whose FIREBASE_API_KEY was never injected. The form is
                // hidden in that case, so this should be unreachable.
                return "ההתחברות הישירה לא זמינה בגרסה הזאת"
            case .badCredentials:
                // One message for "no such user" and "wrong password" on
                // purpose: telling them apart lets a stranger discover which of
                // our clients' addresses are real.
                return "המייל או הסיסמה שגויים"
            case .tooManyAttempts:
                return "יותר מדי ניסיונות. נסה שוב בעוד כמה דקות"
            case .accountDisabled:
                return "החשבון הזה מושבת. פנה ליועץ שלך"
            case .offline:
                return "אין חיבור לאינטרנט"
            case .server(let message):
                return message
            }
        }
    }

    /// Credentials in, device token out.
    static func signIn(email: String, password: String) async throws -> String {
        let idToken = try await firebaseIDToken(email: email, password: password)
        return try await deviceToken(idToken: idToken)
    }

    /// Asks Google to mail a reset link. Deliberately native too: routing this
    /// through `UIApplication.shared.open` would reintroduce the exact jump to
    /// the default browser that got us rejected.
    static func sendPasswordReset(email: String) async throws {
        guard let url = Config.sendOobCodeEndpoint else { throw Failure.notConfigured }

        var request = googleRequest(url)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "requestType": "PASSWORD_RESET",
            "email": email,
        ])

        let (data, response) = try await send(request)
        let body = json(data)
        if body["email"] != nil { return }

        // EMAIL_NOT_FOUND resolves as success on purpose — the same
        // address-enumeration reasoning as badCredentials above.
        let code = errorCode(body)
        if code == "EMAIL_NOT_FOUND" { return }
        if code == "TOO_MANY_ATTEMPTS_TRY_LATER" { throw Failure.tooManyAttempts }
        throw Failure.server("שליחת המייל נכשלה (\(status(response)))")
    }

    // MARK: - Step 1: credentials to Firebase ID token

    private static func firebaseIDToken(email: String, password: String) async throws -> String {
        guard let url = Config.passwordSignInEndpoint else { throw Failure.notConfigured }

        var request = googleRequest(url)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true,
        ])

        let (data, response) = try await send(request)
        let body = json(data)

        if let idToken = body["idToken"] as? String, !idToken.isEmpty { return idToken }

        switch errorCode(body) {
        case "EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS",
             "INVALID_EMAIL", "MISSING_PASSWORD", "MISSING_EMAIL":
            throw Failure.badCredentials
        case "TOO_MANY_ATTEMPTS_TRY_LATER":
            throw Failure.tooManyAttempts
        case "USER_DISABLED":
            throw Failure.accountDisabled
        default:
            throw Failure.server("ההתחברות נכשלה (\(status(response)))")
        }
    }

    // MARK: - Step 2: ID token to device token

    private static func deviceToken(idToken: String) async throws -> String {
        var request = URLRequest(url: Config.deviceTokenEndpoint)
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let (data, response) = try await send(request)
        let body = json(data)

        if let token = body["token"] as? String, !token.isEmpty { return token }
        // That route answers in Hebrew already and its wording says what to do
        // next, so it beats anything we could invent here.
        if let message = body["error"] as? String, !message.isEmpty { throw Failure.server(message) }
        throw Failure.server("החיבור למכשיר נכשל (\(status(response)))")
    }

    // MARK: - Plumbing

    private static func googleRequest(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 🔴 Load-bearing. A key restricted to this app is enforced through this
        // header, which the Firebase SDKs send for you and URLSession does not.
        // Without it a correctly restricted key answers 403 on every call.
        request.setValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.timeoutInterval = 20
        return request
    }

    private static func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch is URLError {
            // Every URLError reads the same to the person holding the phone.
            throw Failure.offline
        }
    }

    private static func json(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    /// Identity Toolkit answers `{ error: { message: "CODE : free text" } }`.
    private static func errorCode(_ body: [String: Any]) -> String {
        let raw = (body["error"] as? [String: Any])?["message"] as? String ?? ""
        return raw.components(separatedBy: " ").first ?? raw
    }

    private static func status(_ response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? 0
    }
}
