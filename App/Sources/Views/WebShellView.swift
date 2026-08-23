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
    @State private var showSignIn = false
    @State private var connect = ConnectSession()

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
        .sheet(isPresented: $showSignIn) {
            SignInSheet(isPresented: $showSignIn)
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
            // The same native form the other two entry points use. It must not
            // fall back to /connect while a key exists: that page carries a
            // Google button, and guideline 4.8 is only out of scope while the
            // app offers no third-party login service at all.
            if Config.firebaseAPIKey.isEmpty {
                connect.start { token in appState.setToken(token) }
            } else {
                showSignIn = true
            }
        case "settings":
            showSettings = true
        default:
            break
        }
    }
}
