import SwiftUI

// First-run screen: brand + one button that opens the login page in system
// Safari (Google OAuth is blocked inside webviews). The page returns the
// device token via the mipuytracker:// deep link and RootView flips onward.
struct OnboardingView: View {
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

            Text("ההתחברות נפתחת בדפדפן ותחזור לכאן לבד")
                .font(.footnote)
                .foregroundStyle(Brand.mutedText)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.surface)
    }
}
