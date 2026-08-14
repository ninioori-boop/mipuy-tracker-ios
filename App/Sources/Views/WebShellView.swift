import SwiftUI

// The main screen once connected: the real expenses tab, full screen.
// A floating gear opens native settings (also our guideline-4.2 surface).
struct WebShellView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false
    @State private var connect = ConnectSession()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let token = appState.token {
                WebView(url: Config.expensesURL(token: token)) { deepLink in
                    handle(deepLink)
                }
                .id(token)
                .ignoresSafeArea(edges: .bottom)
            }

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Brand.mutedText.opacity(0.7))
                    .padding(10)
            }
            .accessibilityLabel("הגדרות")
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
