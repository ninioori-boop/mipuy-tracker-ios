import SwiftUI

/// The automation step, promoted into the first-run flow.
///
/// The guide itself already existed — but it lived behind the gear icon in
/// Settings, which a brand-new user has no reason to tap. So a client could
/// install the app, sign in, see their expenses, and conclude they were done,
/// while the one thing the app exists for was never set up and nothing was ever
/// captured. Ori hit exactly this on the first real install (2026-08-14) and
/// called it out. Now it is a step you have to walk past, not a page to find.
struct AutomationSetupView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AutomationGuideView()

                VStack(spacing: 10) {
                    Button {
                        appState.markAutomationSetup()
                    } label: {
                        Text("סיימתי, המשך לאפליקציה")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Brand.gold)
                            .foregroundStyle(Brand.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // An escape hatch on purpose. Someone setting the app up on
                    // the bus should not be stuck on this screen; the guide stays
                    // in Settings, and the app tells them when a charge failed to
                    // record anyway.
                    Button("אעשה את זה אחר כך") {
                        appState.markAutomationSetup()
                    }
                    .font(.footnote)
                    .foregroundStyle(Brand.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .background(Brand.surface)
            }
            .background(Brand.surface)
        }
    }
}
