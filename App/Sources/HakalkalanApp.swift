import SwiftUI

@main
struct HakalkalanApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // mipuytracker://token/<token> — the /connect page hands the device token
    // back after login in system Safari (same contract as Android).
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == Config.scheme else { return }
        switch url.host {
        case "token":
            let token = url.lastPathComponent
            if !token.isEmpty, token != "token" {
                appState.setToken(token.removingPercentEncoding ?? token)
            }
        default:
            break
        }
    }
}
