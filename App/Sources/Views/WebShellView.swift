import SwiftUI

// The main screen once connected: the real expenses tab, full screen.
//
// Settings are reached through the web menu's "הגדרות האפליקציה בטלפון" row,
// which fires mipuytracker://settings and lands in the `settings` case below.
// There used to be a floating gear here as well; it overlapped the page's own
// hamburger and duplicated a route the menu already offered.
struct WebShellView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        Group {
            if let token = appState.token {
                WebView(url: Config.expensesURL(token: token)) { deepLink in
                    handle(deepLink)
                }
                .id(token)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Brand.surface)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func handle(_ url: URL) {
        switch url.host {
        case "token":
            let token = url.lastPathComponent
            if !token.isEmpty, token != "token" {
                appState.setToken(token.removingPercentEncoding ?? token)
            }
        case "reauth":
            // Full Safari, not an in-app sheet: signInWithPopup needs a second
            // window and a sheet has none, which black-screens sign-in. See the
            // header of OnboardingView.
            UIApplication.shared.open(Config.connectURL)
        case "settings":
            showSettings = true
        default:
            break
        }
    }
}
