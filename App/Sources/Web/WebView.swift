import SwiftUI
import WebKit

// WKWebView wrapper — the iOS twin of the Android WebView shell.
// Loads /connect/expenses#token=… (that page mints the web session itself),
// intercepts mipuytracker:// links, sends external links to Safari, and
// bridges JS alert/confirm/prompt (WKWebView silently swallows them otherwise).
struct WebView: UIViewRepresentable {
    let url: URL
    var onDeepLink: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        // ExtSchemes/1 is a promise to the web app, not decoration: canOpenExternalSchemes()
        // in src/lib/isEmbedded.ts hides every whatsapp:/tel:/mailto: link from a shell
        // that does not claim it, because a raw WebView dies on those with
        // ERR_UNKNOWN_URL_SCHEME. Without it the WhatsApp connect button is simply not
        // offered on iPhone. Only add the flag while decidePolicyFor below still honours it.
        webView.customUserAgent = (WKWebView().value(forKey: "userAgent") as? String ?? "Mozilla/5.0")
            + " MipuyiOS/1.0 ExtSchemes/1"
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Brand.surface)
        webView.scrollView.backgroundColor = UIColor(Brand.surface)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // The shell reloads only on cold start; state changes recreate the view
        // via .id() in WebShellView when the token changes.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDeepLink: onDeepLink)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let onDeepLink: (URL) -> Void
        private let allowedHosts: Set<String> = [
            "app.orimipuy.com",
            "mipuy-financi-app-2-3nay.vercel.app",
            "orimipuy.com",
        ]

        init(onDeepLink: @escaping (URL) -> Void) {
            self.onDeepLink = onDeepLink
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if url.scheme == Config.scheme {
                onDeepLink(url)
                decisionHandler(.cancel)
                return
            }
            // Anything that is not a web page — whatsapp:, tel:, mailto:, sms: —
            // belongs to another app. WKWebView cannot load these and fails
            // silently, so before this the WhatsApp bot button did nothing at all.
            // about:/data:/blob: stay inside: they are the web view's own plumbing.
            if let scheme = url.scheme?.lowercased(),
               !["http", "https", "about", "data", "blob", "file"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            // Sub-frames stay inside, whatever their host. This handler fires for
            // every frame, and until 2026-09-02 the external-link rule below never
            // asked which one: the day the web app started loading reCAPTCHA
            // Enterprise (Firebase App Check), its www.google.com iframe was
            // thrown at Safari as if the client had tapped a link — a blank
            // google.com page — and cancelled here, so the page behind it hung on
            // a spinner waiting for a token that could never arrive. Every iPhone
            // client was locked out of the app on the first open after that deploy.
            // A frame the page embeds is the page's own business; only a
            // top-level navigation (or a target=_blank, whose targetFrame is nil)
            // is the client leaving the app.
            if let target = navigationAction.targetFrame, !target.isMainFrame {
                decisionHandler(.allow)
                return
            }
            // External links (and target=_blank) open in Safari.
            if let host = url.host,
               ["http", "https"].contains(url.scheme ?? ""),
               !allowedHosts.contains(host) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // MARK: JS dialogs

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            presentAlert(message: message, actions: [("אישור", { completionHandler() })])
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            presentAlert(message: message, actions: [
                ("ביטול", { completionHandler(false) }),
                ("אישור", { completionHandler(true) }),
            ])
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            // The web app doesn't use prompt(); answer with the default.
            completionHandler(defaultText)
        }

        private func presentAlert(message: String, actions: [(String, () -> Void)]) {
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController
            else {
                actions.last?.1()
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            for (title, handler) in actions {
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in handler() })
            }
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            presenter.present(alert, animated: true)
        }
    }
}
