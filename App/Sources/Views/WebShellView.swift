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
    }

    private func handle(_ url: URL) {
        switch url.host {
        case "token":
            let token = url.lastPathComponent
            if !token.isEmpty, token != "token" {
                appState.setToken(token.removingPercentEncoding ?? token)
            }
        case "reauth":
            // Google OAuth can't run inside a webview. The Safari sheet can do
            // it and, unlike a jump to Safari proper, closes itself afterwards
            // instead of stranding the user on a blank tab.
            connect.start { token in appState.setToken(token) }
        case "settings":
            showSettings = true
        default:
            break
        }
    }
}
