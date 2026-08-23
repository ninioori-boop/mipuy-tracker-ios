import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDisconnect = false
    @State private var showSignIn = false
    @State private var connect = ConnectSession()

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("חיבור") {
                    HStack {
                        Text("סטטוס")
                        Spacer()
                        Text(appState.token == nil ? "לא מחובר" : "מחובר ✓")
                            .foregroundStyle(appState.token == nil ? Brand.expense : Brand.income)
                    }
                    // The third way into sign-in, and the easiest to forget: it
                    // once jumped to full Safari while the other two had already
                    // been moved into the app sheet. That is the exact thing
                    // guideline 4 rejected 1.0 (21) for, reachable in two taps.
                    // It now shows the same native form as the first-run screen.
                    Button("התחבר מחדש") {
                        if Config.firebaseAPIKey.isEmpty {
                            connect.start { token in appState.setToken(token) }
                        } else {
                            showSignIn = true
                        }
                    }
                    Button("נתק את החשבון", role: .destructive) {
                        confirmDisconnect = true
                    }
                }

                Section("קליטה אוטומטית") {
                    NavigationLink("מדריך הקמת האוטומציה") {
                        AutomationGuideView()
                    }
                }

                Section("התראות") {
                    Button("הגדרות התראות של האפליקציה") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("גרסה")
                        Spacer()
                        Text(version).foregroundStyle(Brand.mutedText)
                    }
                }
            }
            .navigationTitle("הגדרות")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("סגור") { dismiss() }
                }
            }
            .sheet(isPresented: $showSignIn) {
                SignInSheet(isPresented: $showSignIn)
            }
            .confirmationDialog("לנתק את החשבון מהמכשיר?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
                Button("נתק", role: .destructive) {
                    appState.disconnect()
                    dismiss()
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
    }
}
