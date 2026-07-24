import AppIntents

// Registers the capture intent as an App Shortcut so it appears in the
// Shortcuts app and the Wallet-automation picker with ZERO user authoring.
// Siri phrases must be in Siri-supported locales (no Hebrew Siri) — English
// phrases here; the DISPLAYED title stays Hebrew via the intent's title.
struct HakalkalanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureTransactionIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "Record a payment in \(.applicationName)",
            ],
            shortTitle: "רישום הוצאה",
            systemImageName: "creditcard.fill"
        )
    }
}
