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

    // inputConnectionBehavior is what makes this automatic. Without it Shortcuts
    // leaves the parameter unbound, and an unbound required parameter makes iOS
    // stop and ASK the user to type the charge — which defeats the entire point
    // and cannot work on a locked phone. Verified on a real charge 2026-08-14:
    // the automation fired, then prompted for text. With this, Shortcuts wires
    // the Wallet trigger's transaction straight in, and no client has to know
    // what a variable is.
    @Parameter(title: "פרטי העסקה", inputConnectionBehavior: .connectToPreviousIntentResult)
    var details: String

    func perform() async throws -> some IntentResult {
        guard let token = KeychainStore.loadToken() else {
            Notifier.showConnectPrompt()
            return .result()
        }

        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // An empty payload means the automation is misconfigured. Returning
            // quietly here would drop a real charge and look like nothing ever
            // happened, which is the one failure mode this app must not have.
            Notifier.showEmptyPayload()
            return .result()
        }

        do {
            let response = try await post(token: token, merchant: trimmed)
            if let notify = response["notify"] as? [String: Any],
               let title = notify["title"] as? String {
                let body = notify["body"] as? String ?? ""
                let warn = notify["warn"] as? Bool ?? false
                Notifier.show(title: title, body: body, warn: warn)
            }
        } catch {
            // Never lose a charge silently — surface it for manual entry.
            Notifier.showFailure(details: trimmed)
        }
        return .result()
    }

    private func post(token: String, merchant: String) async throws -> [String: Any] {
        var request = URLRequest(url: Config.transactionEndpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "token": token,
            "merchant": merchant,
        ])

        // One retry on transport errors (flaky cellular right after a tap).
        var lastError: Error = URLError(.unknown)
        for _ in 0..<2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard (200..<300).contains(http.statusCode) else {
                    // 4xx = the server rejected (bad token / unparseable) — no retry.
                    throw URLError(.badServerResponse)
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
