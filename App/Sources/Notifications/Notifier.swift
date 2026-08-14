import Foundation
import UserNotifications

// Local notifications — the iOS analog of the Android Notifier's two channels:
// warn=false → passive confirmation, warn=true → time-sensitive budget alert.
// All driven by the server's notify{title, body, warn} response; no push/FCM.
enum Notifier {
    static func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func show(title: String, body: String, warn: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.interruptionLevel = warn ? .timeSensitive : .passive
        if warn { content.sound = .default }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func showConnectPrompt() {
        show(
            title: "האפליקציה לא מחוברת",
            body: "פתח את הכלכלן של הבית והתחבר כדי שהתשלומים יירשמו",
            warn: true
        )
    }

    static func showEmptyPayload() {
        show(
            title: "תשלום לא נרשם",
            body: "החיוב זוהה אבל הפרטים הגיעו ריקים. אפשר להוסיף ידנית באפליקציה.",
            warn: true
        )
    }

    static func showFailure(details: String) {
        show(
            title: "תשלום לא נרשם",
            body: "לא הצלחנו לרשום: \(details.prefix(60)). אפשר להוסיף ידנית באפליקציה.",
            warn: true
        )
    }
}
