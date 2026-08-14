import SwiftUI

// First-run screen: brand + one button that opens the login page in a Safari
// sheet (Google OAuth is blocked inside webviews). The page hands back the
// device token via the mipuytracker:// callback, the sheet closes itself, and
// RootView flips onward — see ConnectSession for why this is not a Safari jump.
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
