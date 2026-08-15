import SwiftUI

// First-run screen: brand + one button that opens the login page in full Safari.
// The page hands the device token back over the mipuytracker:// deep link and
// RootView flips onward.
//
// 🔴 This deliberately does NOT use ASWebAuthenticationSession. That sheet was
// tried (3f154b2) to stop Safari being left open on a blank tab afterwards, and
// it broke sign-in outright: Firebase's signInWithPopup needs to open a second
// window, the sheet gives it nowhere to go, and the user watches a black screen
// spin forever. Found on a real device 2026-08-15 while reconnecting an account.
// A leftover tab is an annoyance; a sign-in that cannot complete is the product.
// Do not reintroduce the sheet before /connect is same-origin and switched to
// signInWithRedirect — see project_google_signin_blank_tab.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("הכלכלן של הבית")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(Brand.gold)

            Text("מעקב הוצאות אוטומטי")
                .font(.title3)
                .foregroundStyle(Brand.mutedText)

            Text("כל תשלום Apple Pay נרשם מעצמו,\nעם התראה כמה נשאר בתקציב.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.text)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                UIApplication.shared.open(Config.connectURL)
            } label: {
                Text("התחבר עם החשבון שלך")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Brand.gold)
                    .foregroundStyle(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Text("ההתחברות נפתחת בספארי. בסיום חוזרים לכאן")
                .font(.footnote)
                .foregroundStyle(Brand.mutedText)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.surface)
    }
}
