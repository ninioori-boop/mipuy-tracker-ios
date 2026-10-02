import AppIntents
import Foundation

// The heart of the app: the action a client's Wallet automation runs on every
// Apple Pay tap. Single string parameter — the server's extractFromRaw()
// splits amount + merchant out of the raw text, so the client maps at most
// ONE field (often auto-bound). Runs in the background (no app launch, no UI,
// no prompts — it must work with the phone locked).
struct CaptureTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "רישום הוצאה"
    static var description = IntentDescription(
        "רושם תשלום בתיעוד ההוצאות של הכלכלן של הבית"
    )
    static var openAppWhenRun = false

    // Kept, but do not mistake it for automatic binding — it was tried for
    // exactly that and does not work here. It connects the parameter to the
    // PREVIOUS INTENT'S RESULT, and in a Wallet automation this action is the
    // first and only one, so there is no previous result and the Wallet
    // transaction is not offered as one. Retested on a real charge 2026-08-14:
    // iOS still stopped and asked the user to type the purchase.
    //
    // Apple gives no way to bind the trigger's transaction from our side. The
    // client has to attach «קלט של קיצור» / Shortcut Input to this field once,
    // by hand, which is why that is now step 6 of the in-app guide and flagged
    // there as the one step that must not be skipped. Skipping it produces an
    // automation that looks perfectly set up and prompts for every purchase —
    // and cannot work at all while the phone is locked, which is every Apple
    // Pay tap.
    @Parameter(title: "פרטי העסקה", inputConnectionBehavior: .connectToPreviousIntentResult)
    var details: String

    func perform() async throws -> some IntentResult {
        guard let token = KeychainStore.loadToken() else {
            Notifier.showConnectPrompt()
            return .result()
        }

        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // An empty payload: the Wallet automation ran, but iOS handed it no
            // amount and no merchant. Returning quietly here would drop a real
            // charge and look like nothing ever happened, which is the one
            // failure mode this app must not have.
            Notifier.showEmptyPayload()
            // ...and tell the server, which until 1.0.5 never heard of it. Four
            // clients had never captured a charge (02/10/2026) and the server
            // held no trace of a single one of them. The notification goes
            // first, so a slow network can never delay the person's warning.
            await reportEmptyPayload(token: token)
            return .result()
        }

        do {
            let response = try await post(token: token, merchant: trimmed)
            Notifier.show(serverNotify: response)
        } catch let refusal as ServerRefusal {
            if refusal.status == 401 {
                // The server's 401 text tells a Safari-shortcut user to paste a
                // new code into the shortcut. This app has no code to paste: its
                // fix is signing in again, which is what this prompt says.
                Notifier.showConnectPrompt()
            } else if let title = refusal.title {
                // The server said WHY (a refund, an issuer notice, the service
                // being down...). Its sentence is the useful one. The charge
                // itself rides along, because every one of these tells the
                // person to type it in by hand, and they need to see what.
                Notifier.show(title: title, body: refusal.body + "\n" + String(trimmed.prefix(60)), warn: true)
            } else {
                Notifier.showFailure(details: trimmed)
            }
        } catch {
            // Never lose a charge silently — surface it for manual entry.
            Notifier.showFailure(details: trimmed)
        }
        return .result()
    }

    /// Best effort, one attempt, short timeout. The person has already been
    /// warned; this exists only so that we can see it too.
    private func reportEmptyPayload(token: String) async {
        var request = URLRequest(url: Config.transactionEndpoint, timeoutInterval: 8)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "token": token,
            "merchant": "",
            "report": "empty-payload",
            "client": Self.clientInfo,
        ])
        _ = try? await URLSession.shared.data(for: request)
    }

    /// Which iOS and which build, so a breadcrumb answers "which version?"
    /// without anyone asking the client to dig through Settings.
    /// ProcessInfo rather than UIDevice: no main actor needed in the intent.
    static var clientInfo: [String: String] {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let info = Bundle.main.infoDictionary
        let app = "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
        return ["os": "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)", "app": app]
    }

    private func post(token: String, merchant: String) async throws -> [String: Any] {
        var request = URLRequest(url: Config.transactionEndpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "token": token,
            "merchant": merchant,
            "client": Self.clientInfo,
        ])

        // One retry on transport errors (flaky cellular right after a tap).
        var lastError: Error = URLError(.unknown)
        for _ in 0..<2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard (200..<300).contains(http.statusCode) else {
                    // 4xx = the server rejected (bad token / unparseable) — no retry.
                    // Every refusal carries a `notify` written for the person, so
                    // hand the body up instead of discarding it.
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                    let notify = json?["notify"] as? [String: Any]
                    throw ServerRefusal(
                        status: http.statusCode,
                        title: notify?["title"] as? String,
                        body: notify?["body"] as? String ?? ""
                    )
                }
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                return json ?? [:]
            } catch let error as URLError where error.code != .badServerResponse {
                lastError = error
                continue
            }
        }
        throw lastError
    }
}

/// A non-2xx answer from /api/transaction, with the sentence it carried for
/// the person, if any. Not a URLError, so the transport-retry loop above never
/// retries it. Plain strings only, so the error stays Sendable.
struct ServerRefusal: Error {
    let status: Int
    let title: String?
    let body: String
}
