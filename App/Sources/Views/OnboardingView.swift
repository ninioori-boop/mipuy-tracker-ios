import SwiftUI

// First-run screen: brand, then a native email + password form.
//
// History worth keeping, because this screen has been rebuilt three times and
// each rebuild was a response to a real rejection:
//   • It opened full Safari. Apple rejected 1.0 (21) under guideline 4 for it,
//     twice — the second time because the fixed build was never actually
//     attached to the submission.
//   • Build 22 moved sign-in into an in-app sheet (see ConnectSession), which
//     satisfies the letter of the guideline.
//   • This version stops arguing: the primary path is a native form that talks
//     straight to Google and to our own /api/device-token, and no browser is
//     involved at all. Google remains as a second option.
//
// The sheet is still the fallback for a build whose FIREBASE_API_KEY was not
// injected. A build that cannot sign in at all is far worse than one that signs
// in the older, compliant way.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var connect = ConnectSession()

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("הכלכלן של הבית")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Brand.gold)
                    .padding(.top, 24)

                Text("מעקב הוצאות אוטומטי")
                    .font(.title3)
                    .foregroundStyle(Brand.mutedText)

                Text("כל תשלום Apple Pay נרשם מעצמו,\nעם התראה כמה נשאר בתקציב.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Brand.text)
                    .padding(.bottom, 8)

                if Config.firebaseAPIKey.isEmpty {
                    legacySheetButton
                } else {
                    SignInForm { token in appState.setToken(token) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var legacySheetButton: some View {
        VStack(spacing: 12) {
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

            Text("ההתחברות נפתחת כאן ונסגרת לבד בסיום")
                .font(.footnote)
                .foregroundStyle(Brand.mutedText)
        }
    }
}
