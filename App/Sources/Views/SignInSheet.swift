import SwiftUI

/// The sign-in form presented as a sheet, with its own chrome.
///
/// Exists so Settings and the re-auth deep link cannot drift apart. They did
/// exactly that once before: two of the three ways into sign-in were moved
/// in-app and the third kept jumping to Safari for days, which is what
/// guideline 4 refused.
struct SignInSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Painted behind the scroll view: a sheet's own backdrop shows
                // through around the safe areas otherwise, and a pale strip
                // under a dark form reads as a half-loaded screen.
                Brand.surface.ignoresSafeArea()
                ScrollView {
                    SignInForm { token in
                        appState.setToken(token)
                        isPresented = false
                    }
                    .padding(24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("התחברות")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { isPresented = false }
                }
            }
        }
        // A sheet is its own presentation context: without these two it renders
        // left-to-right and light, unlike every other screen.
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
    }
}
