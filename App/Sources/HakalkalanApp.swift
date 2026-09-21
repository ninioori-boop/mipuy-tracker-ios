import SwiftUI
import UIKit

/// קיים אך ורק כדי לקבל את טוקן ה-APNs.
///
/// אפל מוסרת אותו דרך ה-UIApplicationDelegate ולא דרך SwiftUI, ואין לכך תחליף:
/// `registerForRemoteNotifications()` בלי delegate שמממש את שתי המתודות האלה
/// פשוט לא מחזיר כלום, בלי שגיאה ובלי לוג.
final class PushDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 🔴 בכל פתיחה, ולא רק אחרי מסך ההרשאה. מי שהתקין לפני הגרסה הזאת כבר
        // עבר את המסך ההוא ולעולם לא יראה אותו שוב. ראה PushRegistration.
        PushRegistration.registerIfPermitted()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushRegistration.send(apnsToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // שקט בכוונה. נכשל בסימולטור, במצב טיסה, ובכל מכשיר בלי הרשאה, ואף אחד
        // מהמקרים האלה אינו תקלה שהמשתמש יכול לעשות איתה משהו.
    }
}

@main
struct HakalkalanApp: App {
    @UIApplicationDelegateAdaptor(PushDelegate.self) private var pushDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // mipuytracker://token/<token> — the /connect page hands the device token
    // back after login in system Safari (same contract as Android).
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == Config.scheme else { return }
        switch url.host {
        case "token":
            let token = url.lastPathComponent
            if !token.isEmpty, token != "token" {
                appState.setToken(token.removingPercentEncoding ?? token)
            }
        default:
            break
        }
    }
}
