import SwiftUI

/// The native sign-in form: two fields and a button, with no web view anywhere
/// in the primary path. Shared by the first-run screen and Settings so the two
/// can never drift apart — the third entry point drifting is precisely what
/// left "התחבר מחדש" jumping to Safari after the other two were fixed.
///
/// Google stays below as a second option, and that is deliberate: Apple's
/// objection was never Google, it was leaving the app for the default browser.
/// With a native form as the primary path, the OAuth sheet is an alternative
/// rather than the only way in.
struct SignInForm: View {
    /// Called with the device token once sign-in succeeds.
    var onToken: (String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var notice = ""
    @State private var busy = false
    @State private var connect = ConnectSession()
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

            HStack(spacing: 10) {
                Rectangle().fill(Brand.mutedText.opacity(0.25)).frame(height: 1)
                Text("או").font(.footnote).foregroundStyle(Brand.mutedText)
                Rectangle().fill(Brand.mutedText.opacity(0.25)).frame(height: 1)
            }
            .padding(.vertical, 6)

            Button {
                connect.start { token in onToken(token) }
            } label: {
                Text("התחבר עם חשבון Google")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Brand.text)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Brand.mutedText.opacity(0.4))
                    )
            }
            .disabled(busy)
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
