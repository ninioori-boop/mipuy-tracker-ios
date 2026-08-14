import AuthenticationServices
import UIKit

/// Sign-in that closes itself.
///
/// The first version called `UIApplication.shared.open` on the login page, which
/// threw the user out into full Safari. The page then fired the mipuytracker://
/// deep link back to us — but Safari stayed open on a blank tab, and the user had
/// to work out for themselves that they were done and find their way back to the
/// app. That is exactly what happened on the first real device test (2026-08-14).
///
/// ASWebAuthenticationSession runs the same page in a Safari sheet that shares
/// Safari's cookies — which is why this cannot be a WKWebView, Google blocks
/// OAuth there — and tears the sheet down the instant the callback scheme fires.
@MainActor
final class ConnectSession: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func start(onToken: @escaping (String) -> Void) {
        let session = ASWebAuthenticationSession(
            url: Config.connectURL,
            callbackURLScheme: Config.scheme
        ) { callbackURL, _ in
            // A cancel gives callbackURL == nil. Nothing to do: the caller stays
            // on the screen it was already showing.
            guard let url = callbackURL, url.host == "token" else { return }
            let raw = url.lastPathComponent
            guard !raw.isEmpty, raw != "token" else { return }
            onToken(raw.removingPercentEncoding ?? raw)
        }
        session.presentationContextProvider = self
        // Deliberately not ephemeral: the whole point is to reuse the Google
        // session the user already has in Safari, so most clients never type a
        // password at all.
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        self.session = session
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}