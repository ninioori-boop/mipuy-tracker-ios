import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.token == nil {
            OnboardingView()
        } else if !appState.didAskNotifications {
            NotificationPermissionView()
        } else {
            WebShellView()
        }
    }
}
