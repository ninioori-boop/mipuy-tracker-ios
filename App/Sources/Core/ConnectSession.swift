import AuthenticationServices
import UIKit

/// Sign-in that happens INSIDE the app, and closes itself when it is done.
///
/// 🔴 Read the history before touching this — it has been added, removed and
/// added back, and each move was correct at the time.
///
/// 1. The first version jumped to full Safari (`UIApplication.shared.open`).
///    The page fired the mipuytracker:// deep link back, but Safari stayed open
///    on a blank tab and the client had to work out for themselves that they
///    were done.
/// 2. So this class arrived (3f154b2) — and broke sign-in outright. Firebase's
///    `signInWithPopup` needs a second window, an ASWebAuthenticationSession has
///    none to give, and the client watched a black screen spin forever.
/// 3. So it was reverted (a1bf2f7), back to full Safari.
/// 4. Apple then rejected 1.0 (21) for exactly that: guideline 4, "the user is
///    taken to the default web browser to sign in, which provides a poor user
///    experience" — plus 2.1(a) for the blank page the popup left behind.
///
/// It only works now because the WEB side changed underneath it: /__/auth/* is
/// proxied from app.orimipuy.com, so Firebase's handler is same-origin, and
/// /connect uses `signInWithRedirect` on iOS. A redirect needs no second window,
/// which is the whole reason this sheet is viable at last.
///
/// ⚠️ If sign-in ever black-screens here again, the cause is a popup coming
/// back — check `signInGoogle` in src/app/connect/page.tsx before touching
/// anything in this file.
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
        // Deliberately not ephemeral: reuse the Google session the user already
        // has in Safari, so most clients never type a password at all. It also
        // keeps the redirect's own state, which lives in same-origin storage.
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
