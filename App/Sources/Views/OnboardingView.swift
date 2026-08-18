import SwiftUI

// First-run screen: brand + one button that opens the login page in a Safari
// sheet INSIDE the app. The page hands the device token back over the
// mipuytracker:// deep link, the sheet closes itself, and RootView flips onward.
//
// The condition that makes the sheet safe — /connect must be same-origin and
// use signInWithRedirect, never a popup — is spelled out in ConnectSession.
// Apple rejected 1.0 (21) for jumping out to the default browser instead.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var connect = ConnectSession()

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
                connect.start { token in appState.setToken(token) }
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

            Text("ההתחברות נפתחת כאן ונסגרת לבד בסיום")
                .font(.footnote)
                .foregroundStyle(Brand.mutedText)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.surface)
    }
}
