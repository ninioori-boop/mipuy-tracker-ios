import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.token == nil {
            OnboardingView()
        } else if !appState.didAskNotifications {
            NotificationPermissionView()
        } else if !appState.didSetupAutomation {
            // Sign in, allow notifications, THEN set up the capture. Skipping
            // this leaves an app that looks finished and records nothing.
            AutomationSetupView()
        } else {
            WebShellView()
        }
    }
}
