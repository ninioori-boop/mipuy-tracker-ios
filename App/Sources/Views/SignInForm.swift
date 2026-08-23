import SwiftUI

/// The native sign-in form: two fields and a button, and nothing else. Shared
/// by every entry point so they cannot drift apart — one of them drifting is
/// precisely what left "התחבר מחדש" jumping to Safari after the other two were
/// fixed.
///
/// 🔴 There is no Google button here, and that is a decision, not an omission.
/// Apple refused 1.0 (24) under guideline 4.8: an app offering a third-party
/// login service must ALSO offer one that lets a user hide their email address
/// from the developer. Email and password does not qualify, because the address
/// reaches us.
///
/// The named remedy is Sign in with Apple, and it is a poor fit here: it hands
/// back a `@privaterelay.appleid.com` address, which can never appear on the
/// invite allowlist, so every such user would land on NotInvitedScreen. The
/// feature would ship broken against this product's own access model.
///
/// Removing the Google button instead takes the guideline out of scope
/// entirely — a rule that does not apply cannot be failed. It cost nothing:
/// the iPhone app had not shipped, so no one depended on it. Google sign-in is
/// untouched on the website and on Android.
struct SignInForm: View {
    /// Called with the device token once sign-in succeeds.
    var onToken: (String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var notice = ""
    @State private var busy = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        !busy && email.contains("@") && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 12) {
            TextField("מייל", text: $email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }
                .modifier(FieldChrome())

            SecureField("סיסמה", text: $password)
                .textContentType(.password)
                .focused($focus, equals: .password)
                .submitLabel(.go)
                .onSubmit { submit() }
                .modifier(FieldChrome())

            if !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Brand.expense)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            if !notice.isEmpty {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(Brand.income)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button(action: submit) {
                ZStack {
                    if busy { ProgressView().tint(Brand.surface) }
                    Text("התחבר").opacity(busy ? 0 : 1)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? Brand.gold : Brand.gold.opacity(0.35))
                .foregroundStyle(Brand.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canSubmit)

            Button("שכחתי סיסמה", action: resetPassword)
                .font(.footnote)
                .foregroundStyle(Brand.mutedText)
                .disabled(busy)
                .padding(.top, 2)

        }
        // 🔴 The keyboard comes up on its own, and that is not a convenience.
        // Apple refused 1.0 (22) on an iPad Air with "the keyboard was not
        // displayed, and we could not enter the demo account credentials":
        // the fields there were a web page inside a sheet, and on iPad running
        // an iPhone app in compatibility mode that combination does not always
        // raise the keyboard. Native fields fix the cause; focusing one of them
        // removes the tap that failed, so a reviewer who lands here can simply
        // start typing.
        //
        // The delay is load-bearing: @FocusState set during the first render is
        // dropped, and the field silently stays unfocused.
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            focus = .email
        }
    }

    private func submit() {
        guard canSubmit else { return }
        focus = nil
        busy = true
        error = ""
        notice = ""
        Task {
            do {
                let token = try await NativeAuth.signIn(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                busy = false
                onToken(token)
            } catch {
                busy = false
                self.error = error.localizedDescription
            }
        }
    }

    private func resetPassword() {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard address.contains("@") else {
            error = "הקלד קודם את המייל שלך, ואז לחץ שוב"
            notice = ""
            return
        }
        focus = nil
        busy = true
        error = ""
        notice = ""
        Task {
            do {
                try await NativeAuth.sendPasswordReset(email: address)
                busy = false
                // Says only what actually happened. An unknown address lands
                // here too, by design, so the wording must not promise that
                // mail is on its way to an account that exists.
                notice = "אם הכתובת רשומה אצלנו, נשלח אליה קישור לאיפוס"
            } catch {
                busy = false
                self.error = error.localizedDescription
            }
        }
    }
}

/// Fields read left-to-right even inside the app's RTL layout: an address or a
/// password typed into a right-aligned box is the kind of small wrongness that
/// makes people think they mistyped.
private struct FieldChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Brand.surface2)
            .foregroundStyle(Brand.text)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Brand.mutedText.opacity(0.25))
            )
    }
}
